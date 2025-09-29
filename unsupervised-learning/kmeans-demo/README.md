# K-means Demo: Customer Purchase Behavior

## Goal
Segment customers into groups based on their purchasing behavior to better understand patterns and target marketing efforts.

This project uses the **Customer Purchase Behavior dataset**, which includes:
- Demographics (age, gender, income, etc.)
- Purchasing metrics (frequency, total spend, categories)
- Behavioral patterns

## Steps Performed

Data preprocessing

Selected numeric variables: Age, Purchase Amount, Review Rating, Previous Purchases.

Cleaned and converted columns to numeric.

Scaled features for clustering.

## K selection

Used Elbow method and Silhouette score for choosing optimal K.

Best K found = 8.

## Clustering

Ran K-means with multiple random starts.

Assigned each customer to a cluster.

## Visualization

Applied PCA to project high-dimensional data to 2D.

Plotted clusters (pca_clusters.png).

## Results

Customers grouped into 8 clusters with distinct profiles.

## Interpretations:

Some clusters represent younger, high-spending customers with frequent purchases.

Others represent older customers with lower spend and fewer purchases.

Review ratings also vary by group, indicating differences in satisfaction.
