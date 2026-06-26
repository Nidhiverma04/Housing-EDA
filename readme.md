
# Portland Housing Market Analytics & ML System

An end-to-end data analytics and machine learning project on 25,000+ Portland residential property records — covering data cleaning, feature engineering, star schema design, SQL analysis, predictive modeling, and Power BI dashboarding.

---

## Project Overview

**Goal:** Identify what drives housing prices in Portland and build a model to predict them.

**Key findings:**

- Living area, location (zip code), and school rating are the top three price drivers
- Homes in 8+ rated school zones command significantly higher prices per sqft
- Luxury properties (top 10%) skew overall RMSE — non-luxury RMSE is $54K vs $134K overall
- 150 data quality outliers identified and removed (<0.6% of dataset): commercial land entries, sub-$10K listings, and implausibly large properties
- Log-transforming price reduced skewness from 36 → -0.35, enabling stable ML modeling

---

## Tech Stack

| Layer               | Tools                                                |
| ------------------- | ---------------------------------------------------- |
| Data Cleaning & EDA | Python, Pandas, NumPy, Matplotlib, Seaborn           |
| Feature Engineering | Python, Pandas                                       |
| Data Warehouse      | MySQL, Star Schema (fact + 4 dimensions)             |
| ETL Pipeline        | Python, SQLAlchemy, batch loading                    |
| SQL Analysis        | MySQL — window functions, CTEs, LAG, PERCENT_RANK   |
| Machine Learning    | XGBoost, scikit-learn, K-Fold CV, log transformation |
| Dashboard           | Power BI (5-page BI system)                          |

---

## Project Structure

```
portland-housing-analytics/
│
├── portland_housing_analysis.ipynb   # Data cleaning, EDA, feature engineering
├── load_data.ipynb                   # Star schema creation + MySQL ETL pipeline
├── ml_model.ipynb                    # XGBoost price prediction model
├── portland_housing_insights.sql     # 25+ SQL analysis queries
├── structure_portland_data.csv       # Cleaned dataset (output of EDA notebook)
└── xgb_predictions.csv              # Model predictions on test set
```

---

## Pipeline Architecture

```
Raw CSV (300+ columns)
        ↓
[1] EDA Notebook — cleaning, outlier removal, feature engineering
        ↓
Structured CSV (~40 features)
        ↓
[2] Load Data Notebook — star schema + MySQL ETL
        ↓
MySQL Database (dim_city, dim_property, dim_school, dim_date, housing fact table)
        ↓
[3] SQL Analysis — business queries, market insights
        ↓
[4] Power BI Dashboard — 5-page interactive BI system
        ↓
[5] ML Notebook — XGBoost price prediction
```

---

## Data Cleaning Highlights

- **Tiered missing value strategy:** dropped columns >80% null; median-imputed numeric columns 50–80% null; frequency-encoded remaining categoricals
- **Context-aware imputation:** bedroom/bathroom zeros filled by home type group median; HOA fees imputed by zip code → property subtype → overall median cascade
- **Outlier removal:** identified and removed 150 bad rows using percentile analysis
  - 7 properties priced above $5M (likely commercial)
  - 41 properties priced below $10K (data entry errors)
  - 82 properties with lot size > 500K sqft (non-residential land)
  - 20 properties with living area > 10K sqft (commercial buildings)
- **Skewness treatment:** log-transformed price, livingArea, lotSize, PricePerSqft — reducing max skewness from 157 to under 1.5

---

## Feature Engineering

15+ business KPIs created:

| Feature              | Formula                          | Business Value              |
| -------------------- | -------------------------------- | --------------------------- |
| PricePerSqft         | price / livingArea               | Normalised price comparison |
| TaxToPriceRatio      | taxAssessedValue / price         | Tax burden indicator        |
| BathroomBedroomRatio | bathrooms / bedrooms             | Home quality proxy          |
| PropertyAge          | soldYear − yearBuilt            | Depreciation signal         |
| AvgSchoolRating      | mean of 3 school ratings         | Location quality            |
| NearestSchool        | min of 3 school distances        | Accessibility               |
| IsLuxury             | top 10% price globally           | Segment flag                |
| IsLargeHome          | top 25% living area              | Size segment flag           |
| numAppliances        | count of non-null appliance cols | Amenity score               |
| numInteriorFeatures  | count of interior feature cols   | Interior quality            |
| avgPriceChangeRate   | mean of price history changes    | Price volatility            |

---

## Star Schema Design

```
         dim_date
             |
dim_city — housing (fact) — dim_property
             |
         dim_school
```

**Fact table:** price, livingArea, lotSize, bedrooms, bathrooms, PricePerSqft, TaxToPriceRatio, propertyAge + 4 foreign keys

**Dimension tables:**

- `dim_city` — address, zipcode, latitude, longitude
- `dim_property` — homeType, homeStatus, architectural style, IsLuxury, IsLargeHome
- `dim_school` — AvgSchoolRating, MaxSchoolRating, MinSchoolDistance
- `dim_date` — soldYear, soldMonth, soldQuarter

---

## SQL Analysis

25+ queries covering:

- Year-over-year price growth (CTE + LAG window function)
- Price percentile ranking per city (PERCENT_RANK)
- 3-month rolling average prices (ROWS BETWEEN)
- School rating impact on price (CASE binning)
- Luxury segment breakdown by city
- Days on market by home type
- Property age bucket pricing

---

## Machine Learning — XGBoost Price Prediction

**Problem:** Predict residential property price from structural and location features.

**Key decisions:**

- Log-transformed target (`log1p(price)`) to handle price skewness
- Target encoding for city and zip code performed **inside** K-Fold loop to prevent data leakage
- Removed `PricePerSqft` and `TaxToPriceRatio` from features — both derived from price (leakage)

**Results:**

| Metric                                                   | Value  |
| -------------------------------------------------------- | ------ |
| CV R² (5-fold)                                          | 0.84   |
| Test R²                                                 | 0.84   |
| RMSE (overall)                                           | ~$134K |
| RMSE (non-luxury, <$600K) | ~$54K (~11% of median price) |        |

**Top price drivers (feature importance):** living area, zip code encoding, tax assessed value, school rating, property age

---

## Power BI Dashboard

5-page interactive BI system:

| Page                | Content                                                   |
| ------------------- | --------------------------------------------------------- |
| Executive KPIs      | Total listings, avg price, avg sqft, avg days on market   |
| Geographic Analysis | Price heatmap by lat/long, top zip codes, city comparison |
| Property Insights   | Price by home type, bedrooms, bathrooms, property age     |
| School Impact       | School rating tiers vs price, nearest school distance     |
| Market Trends       | YoY price trend, seasonal pricing, luxury vs non-luxury   |

---

## How to Run

**1. EDA & Feature Engineering**

```bash
jupyter notebook portland_housing_analysis.ipynb
```

**2. ETL — Load to MySQL**

```bash
# Update MySQL credentials in load_data.ipynb first
jupyter notebook load_data.ipynb
```

**3. SQL Analysis**

```bash
mysql -u root -p portland_house < portland_housing_insights.sql
```

**4. ML Model**

```bash
jupyter notebook ml_model.ipynb
```

---

## Dataset

- **Source:** Portland housing listings (Zillow-style data)
- **Size:** 25,731 records, 300+ raw attributes → cleaned to ~50 analytical features
- **Coverage:** Residential properties across Portland metro area

---
