# Hierarchical Clustering Demo: Customer Segmentation with RFM

## Overview
This demo applies **hierarchical clustering** to customer transaction data (the Online Retail II dataset) to segment
customers based on their **Recency, Frequency, and Monetary (RFM)** behavior. Unlike K-Means or K-Medoids, 
hierarchical clustering does not require a pre-specified number of clusters and instead builds a dendrogram that reveals
nested groupings of customers.

The goal is to uncover customer segments such as **high-value buyers, frequent shoppers, and inactive customers**,
which can inform targeted marketing and retention strategies.

---

## Dataset
- **Source**: [UCI Machine Learning Repository – Online Retail II Dataset](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)  
- **Description**: Transactions from a UK-based online retail company, 2009–2011.  
- **Variables used**:
  - `InvoiceNo`, `InvoiceDate` – purchase information  
  - `Customer ID` – unique customer identifier  
  - `Quantity`, `Price` – used to compute total spend  
  - `Country` – customer’s country  

---

## Methodology
1. **Data Cleaning**
   - Removed missing customer IDs and product descriptions.
   - Filtered out canceled transactions and negative/zero prices.

2. **Feature Engineering**
   - Computed **RFM values** per customer:
     - **Recency**: days since last purchase  
     - **Frequency**: number of distinct invoices  
     - **Monetary**: total spending  

3. **Clustering**
   - Scaled RFM features.  
   - Applied **Agglomerative Hierarchical Clustering (Ward’s method)**.  
   - Chose number of clusters based on dendrogram inspection and interpretability.  

4. **Visualization**
   - **Dendrogram** to illustrate how clusters form.  
   - **Scatter plots** (Frequency vs Monetary, Recency vs Monetary).  
   - **Heatmap** of average RFM values per cluster.  

---

## Results & Interpretation

### Heatmap of Average RFM per Cluster
- **Cluster 4**: Extremely high **Monetary** values → very high-spending customers. Likely a **VIP / premium segment**.  
- **Cluster 1**: Moderate Monetary compared to others → **mid-value buyers**.  
- **Clusters 2 & 3**: Lower Monetary → **budget/infrequent buyers**.  
- Clear separation in monetary contribution, showing **a small group contributes disproportionately to revenue**.  

### Scatter Plot: Frequency vs Monetary
- Most customers have **low frequency and low–medium spend**.  
- A small group (Cluster 4) has **exceptionally high frequency and spending**, visible as outliers in the top-right.  
- Distinct clusters highlight differences between **occasional buyers** and **loyal repeat spenders**.  

---

## Insights
- **High-value segment (Cluster 4)**: Should be nurtured with loyalty programs, exclusive offers, and personalized engagement.  
- **Mid-value customers (Cluster 1)**: Opportunity to upsell/cross-sell.  
- **Low-value / infrequent buyers (Clusters 2 & 3)**: Could be reactivated with discounts or email campaigns.  
- Hierarchical clustering effectively uncovered **natural groupings** without needing to pre-define `k`.  

---

