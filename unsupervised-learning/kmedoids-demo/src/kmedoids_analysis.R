# kmedoids_analysis.R
# Memory-efficient K-Medoids (CLARA) workflow for large dataset (~100k rows)

# ---------------------------
# Libraries
# ---------------------------
library(readr)
library(dplyr)
library(cluster)
library(factoextra)   # for plotting helpers (optional)
library(ggplot2)      # for plots

# ---------------------------
# Step 0: Settings
# ---------------------------
data_path <- "customer_data.csv"
out_path  <- "customer_data_with_clusters.csv"
set.seed(123)

# ---------------------------
# Step 1: Load
# ---------------------------
customer_data <- read_csv(data_path, show_col_types = FALSE)

# ---------------------------
# Step 2: Select numeric features for clustering (exclude id)
# ---------------------------
num_vars <- c("age", "income", "purchase_amount", "promotion_usage", "satisfaction_score")
kmedoids_data <- customer_data %>% select(all_of(num_vars))

# ---------------------------
# Step 3: Preprocess - handle missing values and scale
# ---------------------------
# If you prefer to impute rather than drop, replace the na.omit with appropriate imputation.
kmedoids_data <- na.omit(kmedoids_data)

# Save index mapping if you dropped rows
original_row_ids <- as.integer(rownames(kmedoids_data))  # rownames after na.omit may be characters

kmedoids_scaled <- scale(kmedoids_data)

# ---------------------------
# Step 4: Choose k (sample-based silhouette)
#   - We evaluate silhouette on a sample (fast)
# ---------------------------
sample_size <- 10000
if (nrow(kmedoids_scaled) < sample_size) sample_size <- nrow(kmedoids_scaled)
sample_idx <- sample(seq_len(nrow(kmedoids_scaled)), sample_size)
sample_data <- kmedoids_scaled[sample_idx, , drop = FALSE]

# Evaluate silhouette for k = 2..8 (adjust range if you expect more/less)
k_try <- 2:10
sil_scores <- numeric(length(k_try))

for (i in seq_along(k_try)) {
  k <- k_try[i]
  cl <- clara(sample_data, k = k, metric = "euclid", samples = 5, sampsize = min(1000, nrow(sample_data)))
  # Average silhouette width
  sil <- silhouette(cl$clustering, dist(sample_data))
  sil_scores[i] <- mean(sil[, "sil_width"])
  message("k=", k, " mean silhouette=", round(sil_scores[i], 4))
}

# Plot silhouette vs k (sample-based)
plot(k_try, sil_scores, type = "b", pch = 19,
     xlab = "k (clusters)", ylab = "Mean silhouette (sample)",
     main = "Sample-based silhouette to pick k")

# Choose k with highest silhouette
best_k <- k_try[which.max(sil_scores)]
message("Suggested k (sample-based silhouette) = ", best_k)

# ---------------------------
# Step 5: Run CLARA on full scaled data
#  - samples: number of samples CLARA uses (higher -> more stable, slower)
#  - sampsize: size of each sample (if NULL, CLARA chooses default)
# ---------------------------
clara_samples <- 10     # increase (10-20) if you have more time and want stability
clara_sampsize <- 1000 # CLARA default is 1000; increase for more accurate medoids if memory allows

message("Running CLARA on full data with k=", best_k)
clara_res <- clara(kmedoids_scaled, k = best_k,
                   metric = "euclid",
                   samples = clara_samples,
                   sampsize = clara_sampsize,
                   rngR = TRUE)  # rngR=TRUE makes results reproducible with set.seed

# ---------------------------
# Step 6: Attach clusters back to original dataframe
# ---------------------------
# Note: if you used na.omit earlier, map back carefully. If no rows were removed, below is direct.
customer_data$Cluster <- NA
customer_data$Cluster[as.integer(rownames(kmedoids_data))] <- clara_res$clustering

# Quick cluster counts
table(customer_data$Cluster, useNA = "ifany")

# ---------------------------
# Step 7: Medoids (representative rows)
# ---------------------------
medoid_indices <- clara_res$medoids        # indices w.r.t scaled data rows
medoid_rows <- kmedoids_data[as.integer(as.vector(medoid_indices)), , drop = FALSE]
medoid_rows_df <- as.data.frame(medoid_rows)
message("Medoids (scaled space):")
print(medoid_rows_df)

# To get medoid values in original scale:
# retrieve center values by reversing scale (scale() uses attr "scaled:center" and "scaled:scale")
centers <- attr(kmedoids_scaled, "scaled:center")
scales  <- attr(kmedoids_scaled, "scaled:scale")
medoids_original_scale <- sweep(medoid_rows_df, 2, scales, `*`)
medoids_original_scale <- sweep(medoids_original_scale, 2, centers, `+`)
message("Medoids in original scale:")
print(medoids_original_scale)

# ---------------------------
# Step 8: Summarize clusters
# ---------------------------
cluster_summary <- customer_data %>%
  filter(!is.na(Cluster)) %>%
  group_by(Cluster) %>%
  summarise(
    n = n(),
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(income, na.rm = TRUE),
    mean_purchase_amount = mean(purchase_amount, na.rm = TRUE),
    mean_promotion_usage = mean(promotion_usage, na.rm = TRUE),
    mean_satisfaction_score = mean(satisfaction_score, na.rm = TRUE)
  ) %>%
  arrange(Cluster)

print(cluster_summary)

# ---------------------------
# Step 9: Visualize clusters (use sample to avoid plotting 100k points)
# ---------------------------
viz_sample_idx <- sample(seq_len(nrow(kmedoids_scaled)), min(10000, nrow(kmedoids_scaled)))
viz_sample_scaled <- kmedoids_scaled[viz_sample_idx, , drop = FALSE]

# build a temporary CLARA on the sample to get cluster assignment for plotting
tmp_cl <- clara(viz_sample_scaled, k = best_k, samples = 3, sampsize = min(500, nrow(viz_sample_scaled)))

fviz_cluster(tmp_cl, data = viz_sample_scaled,
             geom = "point", ellipse.type = "norm",
             main = paste("Sample visualization (k=", best_k, ")", sep = ""))

# ---------------------------
# Step 10: Save results
# ---------------------------
write_csv(customer_data, out_path)
message("Clusters saved to: ", out_path)
