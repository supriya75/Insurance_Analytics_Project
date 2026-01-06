# ============================================
# Insurance Analytics Project - Python Analysis
# ============================================
# Author: Supriya Rajendran
# Purpose: Demonstrate end-to-end insurance claims analytics
# Tech Stack: Python (pandas, numpy, matplotlib)
# Dataset: Synthetic insurance claims
# ============================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# --------------------------
# Step 1: Setup & Dataset
# --------------------------
# Creating synthetic claims dataset
data = {
    "claim_id": range(1,21),
    "policy_id": [f"P{100+i}" for i in range(1,21)],
    "region": ["Dubai", "Abu Dhabi", "Sharjah", "Dubai", "Dubai"] * 4,
    "claim_type": ["Medical", "Motor", "Medical", "Medical", "Motor"] * 4,
    "claim_amount": [5000, 12000, 8000, 20000, 15000] * 4,
    "premium": [7000, 10000, 9000, 15000, 12000] * 4,
    "claim_status": ["Approved", "Rejected", "Approved", "Approved", "Pending"] * 4,
    "processing_days": [5, 12, 7, 20, 15] * 4
}

df = pd.DataFrame(data)

# --------------------------
# Step 2: Data Cleaning
# --------------------------
# Check for missing values
print("Any missing values in dataset?", df.isnull().values.any())
print("Missing value counts per column:\n", df.isnull().sum())

# Fill missing values
df["claim_amount"] = df["claim_amount"].fillna(0)
df["premium"] = df["premium"].fillna(df["premium"].median())

# Standardize text columns
df["region"] = df["region"].str.strip().str.lower()
df["claim_status"] = df["claim_status"].str.strip().str.lower()

# --------------------------
# Step 3: Derived Metrics
# --------------------------
# Loss Ratio = claim_amount / premium
df["loss_ratio"] = df["claim_amount"] / df["premium"]

# SLA Breach: flag claims exceeding expected processing days
df["sla_breach"] = np.where(df['processing_days'] > 10, "yes", "no")

# High-Risk Claims: flag claims where loss ratio > 1
df["high_risk_claim"] = np.where(df["loss_ratio"] > 1, "yes", "no")

# --------------------------
# Step 4: Aggregation & Insights
# --------------------------
# Regional summary by claim_type and region
region_summary = df.groupby(["region","claim_type"]).agg({
    "claim_amount": 'sum',
    "premium": 'sum',
    "processing_days": 'mean'
})

# Calculate regional loss ratio
region_summary['regional_loss_ratio'] = region_summary['claim_amount'] / region_summary['premium']

print("\n--- Regional Summary ---")
print(region_summary)

# High-risk or SLA-breaching claims
high_risk_sla = df[(df["high_risk_claim"]=="yes") | (df["sla_breach"] =="yes")]
print("\n--- High-Risk or SLA Breach Claims ---")
print(high_risk_sla[[
    "claim_id","region",'claim_amount','premium',
    'loss_ratio','processing_days','sla_breach','high_risk_claim'
]])

# --------------------------
# Step 5: Visualization
# --------------------------
sns.set_style("darkgrid")

# Total claim amount by region
claims_by_region = df.groupby("region")["claim_amount"].sum()
plt.figure(figsize=(7,5))
claims_by_region.plot(kind='bar', color='skyblue')
plt.title("Total Claim Amount by Region")
plt.xlabel("Region")
plt.ylabel("Claim Amount")
plt.tight_layout()
plt.show()

# Average processing days by region
avg_processing = df.groupby("region")["processing_days"].mean()
plt.figure(figsize=(7,5))
avg_processing.plot(kind='bar', color='orange')
plt.title("Average Processing Days by Region")
plt.xlabel("Region")
plt.ylabel("Days")
plt.tight_layout()
plt.show()

# Claim Amount Distribution
plt.figure(figsize=(7,5))
plt.hist(df["claim_amount"], bins=10, color='green', edgecolor='black')
plt.title("Distribution of Claim Amounts")
plt.xlabel("Claim Amount")
plt.ylabel("Frequency")
plt.tight_layout()
plt.show()

# Average Loss Ratio by Claim Type
loss_by_type = df.groupby('claim_type')['loss_ratio'].mean()
plt.figure(figsize=(7,5))
loss_by_type.plot(kind='bar', color='purple')
plt.title("Average Loss Ratio by Claim Type")
plt.xlabel("Claim Type")
plt.ylabel("Loss Ratio")
plt.tight_layout()
plt.show()

# SLA Breach Counts
sla_counts = df['sla_breach'].value_counts()
plt.figure(figsize=(5,5))
sla_counts.plot(kind='bar', color='red')
plt.title("SLA Breach Counts")
plt.xlabel("SLA Breach")
plt.ylabel("Number of Claims")
plt.tight_layout()
plt.show()
