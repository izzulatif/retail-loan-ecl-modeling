-- Step 1: Temporarily disable foreign keys and truncate tables
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE loan_perf_snapshots;
TRUNCATE TABLE loans;
TRUNCATE TABLE credit_histories;
TRUNCATE TABLE borrowers;
SET FOREIGN_KEY_CHECKS = 1;

-- Enable local infile
SET GLOBAL local_infile = 1;


-- Step 2: Load borrowers
LOAD DATA LOCAL INFILE 'D:/Personal Projects/Retail Loan Portfolio Risk & Expected Credit Loss (ECL) Modeling/borrowers.csv'
INTO TABLE borrowers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- Step 3: Load credit_histories
LOAD DATA LOCAL INFILE 'D:/Personal Projects/Retail Loan Portfolio Risk & Expected Credit Loss (ECL) Modeling/credit_histories.csv'
INTO TABLE credit_histories
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    borrower_id,
    dti,
    open_acc,
    pub_rec,
    revol_bal,
    revol_util,
    total_acc,
    @cr_line
)
SET earliest_cr_line_date = NULLIF(TRIM(REPLACE(@cr_line, '\r', '')), '');


-- Step 4: Load loans
LOAD DATA LOCAL INFILE 'D:/Personal Projects/Retail Loan Portfolio Risk & Expected Credit Loss (ECL) Modeling/loans.csv'
INTO TABLE loans
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    loan_id,
    borrower_id,
    loan_amnt,
    funded_amnt,
    term_months,
    int_rate,
    installment,
    grade,
    sub_grade,
    purpose,
    @issue_dt
)
SET issue_date = NULLIF(TRIM(REPLACE(@issue_dt, '\r', '')), '');


-- Step 5: Load loan_perf_snapshots
LOAD DATA LOCAL INFILE 'D:/Personal Projects/Retail Loan Portfolio Risk & Expected Credit Loss (ECL) Modeling/loan_perf_snapshots.csv'
INTO TABLE loan_perf_snapshots
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    snapshot_id,
    loan_id,
    loan_status,
    total_pymnt,
    total_rec_prncp,
    total_rec_int,
    recoveries,
    @last_pay,
    @next_pay,
    @last_pull
)
SET
    last_pymnt_date       = NULLIF(TRIM(REPLACE(@last_pay, '\r', '')), ''),
    next_pymnt_date       = NULLIF(TRIM(REPLACE(@next_pay, '\r', '')), ''),
    last_credit_pull_date = NULLIF(TRIM(REPLACE(@last_pull, '\r', '')), '');
