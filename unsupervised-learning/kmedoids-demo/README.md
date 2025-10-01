# Customer Segmentation using K-Medoids Clustering

## Project Overview
This project implements K-Medoids clustering for customer segmentation, providing robust grouping of customers based on their characteristics and behaviors.

## Methodology
- **Algorithm**: K-Medoids (PAM - Partitioning Around Medoids)
- **Clusters**: 3 distinct customer segments
- **Variance Explained**: 59.2% total (Dim1: 39%, Dim2: 20.2%)

## Cluster Interpretation

### Cluster 1
- **Profile**: Distinct segment with unique characteristics
- **Position**: Separated group in the feature space
- **Potential Meaning**: Specialized customer group with specific needs/behaviors

### Cluster 2 
- **Profile**: Central/largest customer segment
- **Position**: Middle ground between other clusters
- **Potential Meaning**: Core customer base or "average" profile

### Cluster 3
- **Profile**: Highly distinct segment
- **Position**: Well-separated from other groups
- **Potential Meaning**: Niche segment or customers with extreme characteristics

## Key Advantages of K-Medoids
- **Robustness**: Less sensitive to outliers compared to K-Means
- **Interpretability**: Uses actual data points as cluster centers (medoids)
- **Flexibility**: Works with any distance metric

## Business Applications
- Targeted marketing strategies
- Customer retention programs
- Product recommendation systems
- Resource allocation optimization

## Usage
Run the main analysis script to:
1. Preprocess customer data
2. Perform K-Medoids clustering
3. Generate cluster profiles
4. Create visualization plots
