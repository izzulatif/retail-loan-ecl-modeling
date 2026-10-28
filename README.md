# 🏦 Retail Loan Portfolio Risk & IFRS 9 Expected Credit Loss (ECL) Modeling

![MySQL](https://img.shields.io/badge/Database-MySQL_8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Scikit-Learn](https://img.shields.io/badge/ML-Scikit--Learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)
![Power BI](https://img.shields.io/badge/BI-Power_BI_DAX-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Risk Standard](https://img.shields.io/badge/Standard-IFRS_9_%2F_MFRS_9-0D9488?style=for-the-badge)

## 📌 Executive Summary & Business Problem
Under international financial accounting standards (**IFRS 9 / MFRS 9**), financial institutions must prospectively estimate credit risk and hold sufficient capital reserves to cover **Expected Credit Losses (ECL)**. 

This project builds an end-to-end **Credit Risk Data Engineering & Machine Learning Pipeline** analyzing **1,303,607 matured consumer loans** (with a 20% out-of-sample test portfolio representing **$3.77 Billion in Exposure at Default**). By integrating a relational **MySQL database**, a calibrated **Logistic Regression Probability of Default (PD) scorecard**, and an interactive **Power BI executive dashboard**, this framework quantifies loan-level impairment provisions and identifies critical portfolio concentration risks.

### 🏆 Headline Portfolio Findings (Test Set: 260,722 Matured Loans)
* **Total Portfolio Exposure at Default (EAD):** `$3,768,654,200.00`
* **Required IFRS 9 / MFRS 9 ECL Reserve Buffer:** `$629,294,975.15` (**16.70%** Portfolio ECL Rate)
* **Exceptional Model Calibration:** Average Predicted PD of **20.09%** vs. Actual Observed Default Rate of **20.07%** (Calibration Error of just **+2 bps / +0.02%**).
* **Discriminative Power:** Achieved an out-of-sample **ROC-AUC of 0.6970** and **Gini Coefficient of 0.3940** across highly volatile unsecured consumer credit.
* **Strategic Concentration Alert:** While **Grades F & G** exhibit the highest default severity (ECL rates of **45.19%** and **56.32%**), **Grades C & D** represent the bank's primary dollar vulnerability—accounting for **$1.65B (43.7%) of total exposure** and **$310.0M (49.3%) of total required ECL reserves**.

---

## 🏗️ End-to-End Architecture & Workflow

```text
Raw LendingClub CSVs (1.3M+ Loans)
       │
       ▼
[1. Python ETL & Data Normalization] ──► Standardized ISO-8601 Dates & Relational Split
       │
       ▼
[2. MySQL 8.0 Relational Database]   ──► 4 Normalized Tables + BULK LOAD DATA INFILE
       │
       ▼
[3. SQLAlchemy & Feature Pipeline]   ──► Filtered Matured Outcomes + Scorecard Encoding
       │
       ▼
[4. Scikit-Learn PD & ECL Engine]    ──► Calibrated Logistic Regression (PD × LGD × EAD)
       │
       ▼
[5. Power BI Executive Dashboard]    ──► 9 Explicit DAX Measures & Risk Concentration Matrix
```

---

## 🗄️ Phase 1: Relational Database Design & MySQL Engineering
Rather than analyzing flat files in memory, raw loan records were normalized into a **4-table relational schema** in **MySQL** to mirror enterprise production environments:
1. `borrowers` (`borrower_id` PK, income, employment length, home ownership)
2. `credit_histories` (`borrower_id` FK, DTI, open/total credit lines, revolving utilization, earliest credit line date)
3. `loans` (`loan_id` PK, `borrower_id` FK, funded amount, term, interest rate, installment, grade, sub-grade, issue date)
4. `loan_perf_snapshots` (`snapshot_id` PK, `loan_id` FK, loan status, principal/interest received, post-default recoveries, payment dates)

### 🛠️ Key Data Engineering Challenges Solved
* **Zero-Date (`0000-00-00`) & Missing Timestamp Handling:** MySQL's `LOAD DATA LOCAL INFILE` converts empty date strings into invalid `0000-00-00` placeholders rather than `NULL`. Engineered staging user variables (`@last_pay`, `@next_pay`, `@cr_line`) paired with `NULLIF(TRIM(REPLACE(@var, '\r', '')), '')` to strip Windows CRLF (`\r\n`) carriage returns and store true database `NULL` values.
* **High-Speed Bulk Ingestion:** Utilized `LOAD DATA LOCAL INFILE` with disabled foreign key checks during staging reloads, ingesting **1.3M+ records across 4 tables in seconds**.

---

## 🧮 Phase 2: Actuarial & Regulatory ECL Methodology
Expected Credit Loss is modeled at the individual loan level using the three foundational pillars of credit risk:

$$\text{ECL} = \text{PD} \times \text{LGD} \times \text{EAD}$$

| Component | Definition | Implementation in Pipeline |
| :--- | :--- | :--- |
| **PD (Probability of Default)** | Likelihood that a borrower defaults (`Charged Off`) over the horizon. | Predicted continuously ($0.0 \le \text{PD} \le 1.0$) via calibrated **Logistic Regression** (`predict_proba`). **Active (`Current`) loans were strictly excluded** from training to prevent survival/maturity bias from artificially diluting default rates. |
| **LGD (Loss Given Default)** | Percentage of exposure permanently lost after accounting for post-default collections (`recoveries`). | Derived from historical charge-off recovery rates ($\text{LGD} = 1 - \text{Recovery Rate}$), tiered by risk grade from **65% (Grade A)** to **90% (Grade G)**. |
| **EAD (Exposure at Default)** | Total outstanding principal balance exposed at the moment of default. | Modeled across the test portfolio's funded principal exposure (**$3.77 Billion** total EAD). |

---

## 🤖 Phase 3: Machine Learning PD Scorecard & Risk Drivers

### 1. Model Validation & Calibration Metrics
The dataset of **1,303,607 matured loans** (`Fully Paid` vs. `Charged Off`) was split using an **80/20 stratified train-test split** (`1,042,885` train / `260,722` test) with `StandardScaler` fit strictly on the training partition to prevent data leakage.

* **ROC-AUC Score:** `0.6970`
* **Gini Coefficient:** `0.3940` ($\text{Gini} = 2 \times \text{AUC} - 1$)
* **Mean Predicted PD:** `20.09%` vs. **Actual Default Rate:** `20.07%`

> **💡 Why Unweighted Logistic Regression?** Using `class_weight='balanced'` artificially inflates predicted probabilities toward 50%, destroying probability calibration and massively overstating IFRS 9 dollar reserves. Preserving natural class priors yielded near-perfect portfolio calibration (`+0.02%` gap).

### 2. Feature Importance (Standardized Log-Odds & Odds Ratios)

| Feature | Coefficient (Log-Odds) | Odds Ratio (OR) | Actuarial & Credit Risk Interpretation |
| :--- | :---: | :---: | :--- |
| **`grade_numeric`** | `+0.3408` | **1.4060** | **Primary Risk Driver:** Each downgrade in credit grade increases default odds by **40.6%**, validating internal underwriting scorecards. |
| **`term_months`** | `+0.2229` | **1.2497** | **Horizon Risk:** 60-month loans carry **25.0% higher default odds** than 36-month loans due to extended macroeconomic exposure. |
| **`dti`** | `+0.1677` | **1.1825** | **Debt Burden:** A 1-SD rise in Debt-to-Income ratio increases default odds by **18.3%**. |
| **`int_rate`** | `+0.1593` | **1.1726** | **Adverse Selection & Pricing:** Higher interest rates increase repayment strain, raising default odds by **17.3%**. |
| **`open_acc`** | `+0.1567` | **1.1697** | **Credit Hunger:** More simultaneously active credit lines correlate with higher default risk (**+17.0%**). |
| **`installment`** | `+0.1383` | **1.1484** | **Cashflow Strain:** Higher monthly payment obligations increase default odds by **14.8%**. |
| **`pub_rec`** | `+0.0472` | **1.0483** | **Derogatory History:** Prior public records (bankruptcies/liens) raise default odds by **4.8%**. |
| **`revol_util`** | `+0.0428` | **1.0437** | **Credit Maximization:** Higher credit card utilization signals liquidity stress (**+4.4%**). |
| **`loan_amnt`** | `-0.1040` | **0.9013** | **Underwriting Selection Effect:** Controlling for installment and grade, larger loans show **9.9% lower default odds** due to stricter income gating. |
| **`revol_bal`** | `-0.1429` | **0.8668** | **Credit Capacity:** Higher absolute revolving balances (when controlling for utilization) reflect borrowers with higher credit limits (**-13.3%** odds). |
| **`total_acc`** | `-0.1603` | **0.8518** | **Top Protective Factor:** Seasoned borrowers with deeper lifetime credit histories have **14.8% lower default odds**. |

---

## 📊 Phase 4: Portfolio ECL Breakdown by Loan Grade

| Grade | Loan Count | Total Exposure (EAD) | % of Portfolio EAD | Avg Predicted PD | Assumed LGD | Total Required ECL ($) | ECL % of Exposure |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **A** | 45,193 | $628,419,325.00 | 16.67% | 8.56% | 65.00% | $34,921,179.63 | **5.56%** |
| **B** | 76,121 | $1,006,586,850.00 | 26.71% | 13.44% | 70.00% | $96,621,707.12 | **9.60%** |
| **C** | 73,718 | $1,050,774,300.00 | 27.88% | 20.36% | 75.00% | $166,088,391.87 | **15.81%** |
| **D** | 39,014 | $595,872,500.00 | 15.81% | 29.09% | 80.00% | $143,876,268.50 | **24.15%** |
| **E** | 18,507 | $327,095,500.00 | 8.68% | 40.43% | 82.00% | $111,352,012.84 | **34.04%** |
| **F** | 6,370 | $122,386,450.00 | 3.25% | 52.28% | 85.00% | $55,305,110.17 | **45.19%** |
| **G** | 1,799 | $37,519,275.00 | 1.00% | 62.15% | 90.00% | $21,130,305.01 | **56.32%** |
| **Total / Portfolio** | **260,722** | **$3,768,654,200.00** | **100.00%** | **20.09%** | **73.32%** *(Weighted)* | **$629,294,975.15** | **16.70%** |

---

## 📈 Phase 5: Power BI Executive Dashboard & DAX Architecture
The model outputs (`powerbi_ecl_loan_predictions.csv` and `powerbi_pd_feature_importance.csv`) power a two-page **Power BI Decision Support System**:
* **Page 1 — Executive Portfolio & ECL Provisioning Summary:** Features a 5-card KPI banner, a dual-axis **Exposure vs. ECL Rate Combo Chart**, term concentration breakdown, and a drill-down **Underwriting Risk Matrix**.
* **Page 2 — PD Model Diagnostics & Risk Drivers:** Tracks model calibration across grades (`Predicted PD` vs. `Actual Default Rate`) alongside a diverging **Log-Odds Feature Importance Tornado Chart**.

### Key Explicit DAX Measures Implemented
* **Exposure-Weighted LGD (`SUMX`):** Ensures larger loan exposures carry proportional weight rather than relying on distorted simple averages:
  ```dax
  Weighted Avg LGD (%) = 
  DIVIDE(
      SUMX('powerbi_ecl_loan_predictions', 'powerbi_ecl_loan_predictions'[EAD] * 'powerbi_ecl_loan_predictions'[LGD]), 
      [Total Exposure (EAD)], 0
  )
  ```
* **Dynamic Portfolio Concentration (`ALL`):**
  ```dax
  % of Portfolio EAD = 
  DIVIDE([Total Exposure (EAD)], CALCULATE([Total Exposure (EAD)], ALL('powerbi_ecl_loan_predictions')), 0)
  ```

---

## 💡 Strategic Recommendations for the Credit Committee
1. **Tighten Underwriting on 60-Month Grade C & D Loans:** Grades C and D generate **$310M (49.3%) of total portfolio ECL**, and 60-month terms increase default odds by **25%**. Capping Grade D loan terms at 36 months or lowering DTI thresholds (<25%) will significantly reduce capital reserve requirements.
2. **Risk-Based Pricing Adjustments for Subprime Tiers (E–G):** With ECL rates between **34.04% and 56.32%**, interest rate spreads on Grades E–G must exceed expected loss rates plus cost of capital, or origination volume should be reallocated toward near-prime Grade B/C segments.
3. **Collection Optimization on High-EAD Defaults:** Even a **5% improvement in post-charge-off recovery rates** across Grades C and D would reduce required MFRS 9 / IFRS 9 loss provisions by over **$10M+**.

---

## 🚀 How to Reproduce This Project
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/retail-loan-ecl-modeling.git
   cd retail-loan-ecl-modeling
   ```
2. **Database Setup:** Run `sql/01_schema_and_bulk_load.sql` in MySQL Workbench to create the normalized schema and load the cleaned CSV tables.
3. **Run the Python Pipeline:** Install dependencies (`pip install pandas numpy sqlalchemy mysql-connector-python scikit-learn`) and execute `notebooks/02_pd_ecl_modeling_pipeline.ipynb`.
4. **Explore the Dashboard:** Open `dashboard/Retail_Loan_ECL_Dashboard.pbix` in Power BI Desktop.
