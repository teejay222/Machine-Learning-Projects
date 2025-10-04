# Load required libraries
library(readxl)     # for reading Excel
library(dplyr)      # for data manipulation
library(lubridate)   # for working with dates
library(scale)  # base R scale() works; no extra package needed
library(ggplot2)
library(pheatmap)
library(tibble)

# Path to data
data_path <- "online_retail_II.xlsx"

# Read dataset (first sheet contains 2009-2010, second sheet has 2010-2011)
retail_data1 <- read_excel(data_path, sheet = 1)
retail_data2 <- read_excel(data_path, sheet = 2)

# Combine both years
retail_data <- bind_rows(retail_data1, retail_data2)

# Quick inspection
print(dim(retail_data))       # rows, cols
print(names(retail_data))     # column names
print(head(retail_data, 10))  # first 10 rows
print(summary(retail_data))   # summary of each column

# Count missing values per column
colSums(is.na(retail_data))

# Step 1: Remove rows without CustomerID
retail_clean <- retail_data %>%
  filter(!is.na(`Customer ID`))

# Step 2: Remove cancelled orders (negative quantities)
retail_clean <- retail_clean %>%
  filter(Quantity > 0)

# Step 3: Create TotalPrice column
retail_clean <- retail_clean %>%
  mutate(TotalPrice = Quantity * Price)

# Quick check after cleaning
print(dim(retail_clean))
print(colSums(is.na(retail_clean)))



# Reference date (we'll use the last date in dataset + 1 day)
reference_date <- max(retail_clean$InvoiceDate) + days(1)

# RFM calculation
rfm_table <- retail_clean %>%
  group_by(`Customer ID`) %>%
  summarise(
    Recency = as.numeric(difftime(reference_date, max(InvoiceDate), units = "days")),
    Frequency = n_distinct(Invoice),  
    Monetary = sum(TotalPrice)
  ) %>%
  ungroup()

# Quick check
head(rfm_table, 10)
summary(rfm_table)



# Keep only numeric RFM features
rfm_features <- rfm_table %>%
  select(Recency, Frequency, Monetary)

# Scale the features
rfm_scaled <- scale(rfm_features)

# Compute distance matrix (Euclidean distance)
rfm_dist <- dist(rfm_scaled, method = "euclidean")

# Quick check
print(class(rfm_dist))   # should be "dist"
print(summary(rfm_dist)) # min, max, median distance


# Perform hierarchical clustering
hc <- hclust(rfm_dist, method = "ward.D2")  # Ward's minimum variance method

# Plot dendrogram

plot(hc, labels = FALSE, hang = -1, main = "Hierarchical Clustering Dendrogram", 
     xlab = "Customers", ylab = "Height")
dev.off()

# Cut tree into 4 clusters
cluster_groups <- cutree(hc, k = 4)

# Add cluster assignment to RFM table
rfm_table$Cluster <- cluster_groups

# Check cluster sizes
table(rfm_table$Cluster)



# Compute mean RFM values per cluster
cluster_summary <- rfm_table %>%
  group_by(Cluster) %>%
  summarise(
    Count = n(),
    Mean_Recency = mean(Recency),
    Mean_Frequency = mean(Frequency),
    Mean_Monetary = mean(Monetary)
  ) %>%
  arrange(Cluster)

print(cluster_summary)



# Scatter plot: Frequency vs Monetary, colored by cluster
ggplot(rfm_table, aes(x = Frequency, y = Monetary + 1, color = factor(Cluster))) +
  geom_point(alpha = 0.6) +
  scale_y_log10() +
  labs(title = "Customer Segmentation by Hierarchical Clustering",
       x = "Frequency", y = "Monetary (log scale +1)", color = "Cluster") +
  theme_minimal()



# Aggregate mean RFM per cluster for heatmap
rfm_heat <- rfm_table %>%
  group_by(Cluster) %>%
  summarise(
    Recency = mean(Recency),
    Frequency = mean(Frequency),
    Monetary = mean(Monetary)
  ) %>%
  column_to_rownames("Cluster")

pheatmap(rfm_heat, cluster_rows = FALSE, cluster_cols = FALSE,
         main = "Average RFM per Cluster", color = colorRampPalette(c("white","blue"))(50))


