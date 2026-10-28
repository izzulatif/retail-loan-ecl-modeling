-- Create Database
CREATE DATABASE IF NOT EXISTS retail_loan_risk;
USE retail_loan_risk;

-- Table 1: Borrowers
-- Holds static demographics and financial attributes of the applicant.
CREATE TABLE borrowers (
    borrower_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_title VARCHAR(150),
    emp_length_years INT NULL, -- Extracted as integer (e.g., "< 1 year" -> 0, "10+ years" -> 10)
    home_ownership VARCHAR(20) NOT NULL, -- RENT, OWN, MORTGAGE
    annual_inc DECIMAL(12, 2) NOT NULL,
    verification_status VARCHAR(30), -- Verified, Source Verified, Not Verified
    addr_state CHAR(2), -- US State abbreviation (e.g., "CA")
    zip_code VARCHAR(10)
);

-- Table 2: Credit Histories
-- Holds financial health indicators pulled from Credit Bureaus (like FICO).
CREATE TABLE credit_histories (
    borrower_id INT PRIMARY KEY,
    dti DECIMAL(5, 2) NULL,
    open_acc INT,
    pub_rec INT,
    revol_bal DECIMAL(12, 2),
    revol_util DECIMAL(5, 2) NULL, -- Note: This column in CSV is a string (e.g. "33.5%"), you may need to clean the "%" in Python first!
    total_acc INT,
    earliest_cr_line_date DATE,
    FOREIGN KEY (borrower_id) REFERENCES borrowers(borrower_id) ON DELETE CASCADE
);

-- Table 3: Loans
-- Holds the core loan structural terms decided at funding.
CREATE TABLE loans (
    loan_id VARCHAR(50) PRIMARY KEY, -- Lending Club's unique loan string identifier
    borrower_id INT NOT NULL,
    loan_amnt DECIMAL(10, 2) NOT NULL,
    funded_amnt DECIMAL(10, 2) NOT NULL,
    term_months INT NOT NULL, -- Converted "36 months" string to integer 36 or 60
    int_rate DECIMAL(5, 2) NOT NULL, -- Stored as percentage (e.g., 12.50)
    installment DECIMAL(10, 2) NOT NULL, -- Monthly payment amount
    grade CHAR(1) NOT NULL, -- A, B, C, D, E, F, G
    sub_grade CHAR(2) NOT NULL, -- A1, B3, etc.
    purpose VARCHAR(50), -- debt_consolidation, credit_card, etc.
    issue_date DATE NOT NULL,
    FOREIGN KEY (borrower_id) REFERENCES borrowers(borrower_id) ON DELETE RESTRICT
);

-- Table 4: Loan Performance Snapshots
-- Holds the status of the loan and performance metrics.
-- Note: In a live pipeline, this would be a historical time-series log.
CREATE TABLE loan_perf_snapshots (
    snapshot_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id VARCHAR(50) NOT NULL,
    loan_status VARCHAR(30) NOT NULL, -- Fully Paid, Charged Off, Late, Current, Default
    total_pymnt DECIMAL(12, 2) DEFAULT 0.00, -- Total payments received to date
    total_rec_prncp DECIMAL(12, 2) DEFAULT 0.00, -- Principal received to date
    total_rec_int DECIMAL(12, 2) DEFAULT 0.00, -- Interest received to date
    recoveries DECIMAL(12, 2) DEFAULT 0.00, -- Post-default collections
    last_pymnt_date DATE NULL,
    next_pymnt_date DATE NULL,
    last_credit_pull_date DATE NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
);
