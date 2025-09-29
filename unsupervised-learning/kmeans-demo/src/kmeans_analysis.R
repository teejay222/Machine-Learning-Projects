################################################################################
# K-means: clean, scale, choose k (elbow + silhouette), fit, visualize, save
################################################################################

library(tidyverse)
library(cluster)    # silhouette()
library(factoextra) # fviz_nbclust(), fviz_cluster()

# 1) Start fresh
rm(list = ls())

# 2) Load the data (adjust path if needed)
data_raw <- read.csv("unsupervised-learning/kmeans-demo/data/CustomerPurchaseBehavior.csv",
                     header = TRUE, stringsAsFactors = FALSE, strip.white = TRUE)

# 3) Select the columns we will cluster on (exact names from your dataset)
numeric_data <- data_raw %>%
  select(Age, `Purchase.Amount..USD.`, Review.Rating, Previous.Purchases)

# 4) Clean & convert to numeric robustly (remove non-numeric characters except '.' )
#    This handles things like "$1,200", " 53 ", or accidental text.
numeric_data_clean <- numeric_data %>%
  mutate(across(everything(),
                ~ as.numeric(gsub("[^0-9\\.\\-]", "", .x))
  ))

# 5) Check conversion summary and NAs
cat("Structure after conversion:\n")
print(str(numeric_data_clean))
cat("\nMissing values per column after conversion:\n")
print(colSums(is.na(numeric_data_clean)))

# If many NAs appear, inspect problematic rows
if (sum(is.na(numeric_data_clean)) > 0) {
  cat("\nRows with any NA (show up to 10 rows):\n")
  print(which(apply(numeric_data_clean, 1, function(r) any(is.na(r))))[1:10])
  # optional: view the original rows for the first few problematic indices
  bad_idx <- which(apply(numeric_data_clean, 1, function(r) any(is.na(r))))
  if (length(bad_idx) > 0) print(head(data_raw[bad_idx, ], 10))
}

# 6) Decide how to handle NAs: simple options
#    - If very few NAs: remove rows with any NA
#    - If many: consider imputing (median)
na_count <- sum(is.na(numeric_data_clean))
if (na_count == 0) {
  numeric_for_kmeans <- numeric_data_clean
} else if (na_count <= 10) {
  message("Small number of NAs -> removing rows with NA.")
  numeric_for_kmeans <- na.omit(numeric_data_clean)
} else {
  message("Many NAs -> imputing median for each column.")
  numeric_for_kmeans <- numeric_data_clean %>%
    mutate(across(everything(), ~ ifelse(is.na(.x), median(.x, na.rm = TRUE), .x)))
}

# 7) Scale the data
scaled_data <- scale(numeric_for_kmeans)
colMeans(scaled_data)    # ~0
apply(scaled_data, 2, sd) # ~1

# 8) Use Elbow method (WSS) and Silhouette to choose best k (2..10)
#    We'll compute both and also compute average silhouette widths programmatically.
wss <- function(k) {
  kmeans(scaled_data, centers = k, nstart = 50, iter.max = 100)$tot.withinss
}
k.values <- 2:10
wss_values <- map_dbl(k.values, wss)

# Plot WSS (Elbow)
plot(k.values, wss_values, type = "b", pch = 19, frame = FALSE,
     xlab = "Number of clusters K",
     ylab = "Total within-clusters sum of squares (WSS)")
title("Elbow method: WSS vs K")

# Compute average silhouette widths
avg_sil <- function(k) {
  km <- kmeans(scaled_data, centers = k, nstart = 50, iter.max = 100)
  ss <- silhouette(km$cluster, dist(scaled_data))
  mean(ss[, 3])
}
sil_values <- map_dbl(k.values, avg_sil)

# Plot silhouette avg widths
plot(k.values, sil_values, type = "b", pch = 19, frame = FALSE,
     xlab = "Number of clusters K",
     ylab = "Average silhouette width")
title("Average silhouette width vs K")

# 9) Choose the best k automatically (max silhouette). If tie, prefer elbow heuristic or smaller k
best_k <- k.values[which.max(sil_values)]
cat("Chosen best_k (by silhouette max) =", best_k, "\n")

# 10) Fit final kmeans with best_k
set.seed(1234) # reproducible
final_km <- kmeans(scaled_data, centers = best_k, nstart = 100, iter.max = 200)
cat("Final kmeans tot.withinss:", final_km$tot.withinss, "\n")
cat("Sizes of clusters:\n"); print(final_km$size)
cat("Cluster centers (in scaled space):\n"); print(final_km$centers)

# 11) Add cluster labels back to the original data (for profiling)
#    Note: if we removed/imputed rows, we must align indexes. We'll attach to numeric_for_kmeans rows.
result_df <- data_raw %>%
  slice(as.integer(rownames(numeric_for_kmeans))) %>%   # align original rows
  mutate(Cluster = final_km$cluster)

# 12) Visualize clusters (PCA + fviz_cluster)
pca_res <- prcomp(scaled_data, scale = FALSE)  # PCA on already scaled data
pca_df <- data.frame(pca_res$x[,1:2], cluster = factor(final_km$cluster))

ggplot(pca_df, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(alpha = 0.6, size = 1.5) +
  labs(title = paste("PCA Projection with Clusters (k =", best_k, ")")) +
  theme_minimal()




# 13) Save clustered dataset
write.csv(result_df, "unsupervised-learning/kmeans-demo/data/CustomerPurchaseBehavior_with_clusters.csv", row.names = FALSE)
cat("Saved clustered data to: data/CustomerPurchaseBehavior_with_clusters.csv\n")

final_km$centers


# 14) Optional: examine cluster summaries (profiling)
cluster_summary <- result_df %>%
  group_by(Cluster) %>%
  summarise(
    n = n(),
    mean_age = mean(as.numeric(Age), na.rm = TRUE),
    mean_purchase_usd = mean(as.numeric(`Purchase.Amount..USD.`), na.rm = TRUE),
    mean_rating = mean(as.numeric(Review.Rating), na.rm = TRUE),
    mean_prev_purchases = mean(as.numeric(Previous.Purchases), na.rm = TRUE)
  )
print(cluster_summary)

# --- Cluster centers back to original scale for interpretation -------------
orig_means <- apply(as.data.frame(numeric_for_kmeans), 2, mean, na.rm = TRUE)
orig_sds   <- apply(as.data.frame(numeric_for_kmeans), 2, sd, na.rm = TRUE)

centers_scaled <- final_km$centers
centers_original <- sweep(sweep(centers_scaled, 2, orig_sds, FUN = "*"), 2, orig_means, FUN = "+")
centers_df <- as.data.frame(centers_original) %>% mutate(Cluster = row_number()) %>% select(Cluster, everything())

write.csv(centers_df, "../cluster_centers_original_scale.csv", row.names = FALSE)
message("Saved pca_clusters.png and cluster_centers_original_scale.csv to the kmeans-demo folder")
