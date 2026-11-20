# Indian Toy Market Sales Analysis

An end-to-end data analytics project exploring sales performance, product categories, brand contribution, customer behaviour and regional trends in the Indian toy market.

The project uses **100,000 transaction records** to identify business patterns, improve data quality and generate insights that can support better sales and merchandising decisions.

---

## Project Overview

**Dataset:** 100,000 rows | 26 columns

**Analysis Period:** 2020–2024

**Tools:** Python, Pandas, Matplotlib, Seaborn, MySQL, SQLAlchemy, Jupyter Notebook

The analysis focuses on understanding:

- Which product categories and brands generate the highest revenue?
- How do sales vary across regions and city tiers?
- What proportion of transactions comes from returning customers?
- How do monthly revenue and sales quantities change over time?
- Which sales channels contribute most to regional sales?

---

## Data Cleaning & Preparation

Prepared the raw transaction dataset for reliable analysis by addressing data-quality issues.

**1. Data Standardization**
- Standardized column names and inconsistent category labels.
- Corrected brand names, city aliases, sales channels and customer segments.
- Converted mixed date formats into a consistent datetime format.
- Recreated year, month, month name and weekday columns.

**2. Missing Values**
- Identified 21,951 missing cells across five columns.
- Filled missing numerical values using appropriate group-based medians.
- Handled missing categorical values using group-based or mode-based imputation.
- Filled missing regional information using city-based mapping.

**3. Invalid Values**
- Identified negative product prices and quantities.
- Flagged invalid discount percentages outside the 0–100 range.
- Handled customer ratings outside the valid 0–5 range.

**4. Revenue Calculation & Validation**
- Recalculated net revenue using:

  `Net Revenue = Quantity × Unit Price × (1 - Discount % / 100)`

- Calculated gross revenue before discounts for comparison.
- Validated the calculated revenue against the chosen formula.

**Result:** The cleaned dataset contains 26 columns with no remaining missing values.

---

## SQL Analysis

Loaded the prepared dataset into MySQL for business-oriented analysis.

Used SQL queries to investigate:

- Overall sales and revenue performance.
- Top-performing brands and product categories.
- Revenue contribution by region and city tier.
- Monthly and quarterly sales trends.
- Customer-type distribution and purchasing behaviour.
- Discount patterns and their relationship with sales.
- Product returns and customer ratings.
- Sales-channel performance across regions.

**SQL concepts used:**
- Aggregations and GROUP BY
- JOIN operations
- Subqueries and CTEs
- CASE statements
- Window functions
- Ranking and analytical calculations

---

## Data Visualizations & Key Findings

Created individual visualizations using Matplotlib and Seaborn to communicate business findings.

### 1. Monthly Net Revenue Trends – Top 5 Brands

![Monthly Revenue Trends Top 5 Brands]

- Compares monthly revenue patterns across five leading brands.
- Highlights differences in revenue contribution.
- Helps identify fluctuations in individual brand performance.

### 2. Overall Monthly Net Revenue Trends

![Monthly Net Revenue Trends]

- Tracks monthly net revenue from 2020 to 2024.
- Revenue fluctuates approximately between ₹7.1M and ₹8.8M.
- Shows no consistent upward trend across the observed period.

### 3. Top 10 Brands – Gross vs. Net Revenue

![Brand Revenue Comparison]

- Compares revenue before and after discounts.
- LEGO leads the plotted brand comparison.
- Highlights the difference between gross and net sales.

### 4. Sales Channel Contribution Across Regions

![Sales Channel Contribution]

- Compares the contribution of seven sales channels across four regions.
- Shows a broadly similar channel distribution across regions.
- Helps identify opportunities for region-specific sales strategies.

### 5. Customer Type Distribution

![Customer Type Distribution]

- Returning customers account for 75.8% of transaction records.
- New customers account for 24.2%.
- Highlights the importance of repeat purchasing and customer acquisition.

### 6. Top 10 Product Categories by Net Revenue

![Product Category Revenue]

- STEM Toys generates the highest category revenue at approximately ₹118M.
- Outdoor Toys and Construction Toys follow.
- Helps identify the categories contributing most to overall sales.

### 7. Monthly Performance – Quantity Sold vs. Net Revenue

![Monthly Quantity and Revenue]

- Compares monthly sales volume with net revenue.
- Helps examine whether changes in sales quantity correspond with revenue fluctuations.
- Provides a combined view of sales volume and financial performance.

### 8. Executive Performance Summary

![Executive Performance Summary]

Contains four complementary views:

- Monthly net revenue.
- Quarterly net revenue.
- Monthly quantity sold.
- Monthly average customer rating.

These metrics provide a broader understanding of sales consistency and customer experience.

### 9. Net Revenue Heatmap – Region vs. City Tier

![Regional Revenue Heatmap]

- Compares revenue across four regions and three city tiers.
- West contributes the highest regional revenue at approximately ₹123.29M.
- Tier 1 cities contribute approximately 49.4% of total revenue.
- Highlights differences in regional and city-tier performance.

---

## Key Business Insights

| Area | Finding |
|---|---|
| Product Categories | STEM Toys leads with approximately ₹118M revenue. |
| Brand Performance | LEGO leads the plotted gross and net revenue comparison. |
| Customer Behaviour | Returning customers represent 75.8% of transaction records. |
| Regional Sales | West contributes the highest regional revenue. |
| City Tiers | Tier 1 cities contribute approximately 49.4% of revenue. |
| Monthly Trends | Revenue fluctuates without a sustained upward trend. |
| Sales Channels | Revenue is distributed across multiple channels in all four regions. |

*Note: Category and brand figures are approximate chart-based observations. Regional heatmap figures are derived from the plotted aggregation.*

---

## Business Problems Addressed

This project explores practical business problems that can affect sales and merchandising decisions.

**1. Inconsistent Business Data**

- Addressed inconsistent names, formats and invalid numerical values.
- Prepared a standardized dataset for consistent reporting.

**2. Identifying Revenue-Generating Products**

- Compared product categories and brands.
- Identified leading and lower-contributing product groups.

**3. Understanding Customer Composition**

- Examined new and returning customer transaction shares.
- Highlighted the opportunity to improve new-customer acquisition.

**4. Regional Sales Differences**

- Compared revenue across regions and city tiers.
- Identified geographical differences that can support localized sales planning.

**5. Monitoring Sales Performance**

- Examined monthly and quarterly revenue patterns.
- Compared revenue with sales quantity and customer ratings.

**6. Evaluating Discounts and Revenue**

- Compared gross and net revenue.
- Prepared analytical questions around discount levels and revenue contribution.

---

## Project Structure

```text
Indian-Toy-Market-Analysis/
│
├── data/
│   ├── indian_toy_market_sales_data.csv
│   └── clean_toy_sales.csv
│
├── notebook/
│   ├── clean_toy.ipynb
│   ├── port_sql.ipynb
│   └── visualizing_data.ipynb
│
├── sql/
│   └── toy_sale.sql
│
├── reports/
│   └── Report.pdf
│
├── presentations/
│   └── Presentation.pdf
│
└── README.md
```

---

## Limitations & Further Improvements

- Validate duplicate transaction handling before final reporting.
- Re-run and export SQL results to reconcile all reported metrics.
- Refine return-rate, customer and discount calculations.
- Investigate profitability using actual cost and margin data.
- Explore seasonal patterns and year-over-year sales growth.

---

## Project Deliverables

- Cleaned transaction dataset.
- Python notebooks for data preparation and visualization.
- SQL scripts for business analysis.
- Individual data visualization outputs.
- Detailed PDF analysis report.
- Project presentation.

**Project Focus:** Data Cleaning | Exploratory Data Analysis | SQL | Business Analysis | Data Visualization