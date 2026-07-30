-- =========================================================
-- 1. CREATE SCHEMA
-- =========================================================

CREATE SCHEMA IF NOT EXISTS fds;

-- =========================================================
-- 2. DIMENSION TABLE: dim_department
-- =========================================================

CREATE TABLE IF NOT EXISTS fds.dim_department (
    dept_id INT PRIMARY KEY,
    dept_code VARCHAR(10),
    dept_name VARCHAR(100)
);

INSERT INTO fds.dim_department (dept_id, dept_code, dept_name)
VALUES
(1, '510', 'General Government'),
(2, '520', 'Public Safety'),
(3, '530', 'Utilities'),
(4, '540', 'Transportation'),
(5, '550', 'Natural and Economic Environment'),
(6, '560', 'Social Services'),
(7, '570', 'Culture and Recreation'),
(8, '580', 'Proprietary Funds - Miscellaneous')
ON CONFLICT (dept_id) DO NOTHING;

-- =========================================================
-- 3. FACT TABLE: fact_expenditure
-- =========================================================

CREATE TABLE IF NOT EXISTS fds.fact_expenditure (
    tx_id INT PRIMARY KEY,
    exp_date DATE NOT NULL,
    dept_id INT NOT NULL,
    vendor_name VARCHAR(100),
    amount NUMERIC(15,2),
    description TEXT,
    CONSTRAINT fk_department
        FOREIGN KEY (dept_id)
        REFERENCES fds.dim_department(dept_id)
);

-- =========================================================
-- 4. FDS DATA MART
-- =========================================================

CREATE OR REPLACE VIEW fds.v_fds_mart AS
SELECT
    f.tx_id,
    f.exp_date,
    f.dept_id,
    d.dept_code,
    d.dept_name,
    f.vendor_name,
    f.amount,
    f.description,
    EXTRACT(YEAR FROM f.exp_date) AS fiscal_year,
    EXTRACT(MONTH FROM f.exp_date) AS fiscal_month
FROM fds.fact_expenditure f
LEFT JOIN fds.dim_department d
    ON f.dept_id = d.dept_id;

-- =========================================================
-- 5. TACTICAL ANOMALY (7-DAY SPLIT DETECTION)
-- =========================================================

CREATE OR REPLACE VIEW fds.v_tactical_anomaly AS
SELECT *
FROM (
    SELECT
        tx_id,
        exp_date,
        dept_id,
        vendor_name,
        amount,
        SUM(amount) OVER (
            PARTITION BY vendor_name, dept_id
            ORDER BY exp_date
            RANGE BETWEEN INTERVAL '6 days' PRECEDING
                  AND CURRENT ROW
        ) AS rolling_7day_total
    FROM fds.fact_expenditure
) t
WHERE rolling_7day_total > 40000;

-- =========================================================
-- 6. STRATEGIC ANOMALY (MONOPOLY RISK)
-- =========================================================

CREATE OR REPLACE VIEW fds.v_strategic_anomaly AS
WITH dept_annual AS (
    SELECT
        dept_id,
        EXTRACT(YEAR FROM exp_date) AS fiscal_year,
        SUM(amount) AS total_dept_spend
    FROM fds.fact_expenditure
    GROUP BY
        dept_id,
        EXTRACT(YEAR FROM exp_date)
)
SELECT
    f.vendor_name,
    f.dept_id,
    d.dept_name,
    EXTRACT(YEAR FROM f.exp_date) AS fiscal_year,
    SUM(f.amount) AS annual_vendor_spend,
    da.total_dept_spend,
    ROUND(
        (SUM(f.amount) / da.total_dept_spend) * 100,
        2
    ) AS budget_share_pct
FROM fds.fact_expenditure f
JOIN fds.dim_department d
    ON f.dept_id = d.dept_id
JOIN dept_annual da
    ON f.dept_id = da.dept_id
   AND EXTRACT(YEAR FROM f.exp_date) = da.fiscal_year
GROUP BY
    f.vendor_name,
    f.dept_id,
    d.dept_name,
    EXTRACT(YEAR FROM f.exp_date),
    da.total_dept_spend
HAVING
    SUM(f.amount) > 40000
    AND (SUM(f.amount) / da.total_dept_spend) > 0.2;

-- =========================================================
-- 7. ADMINISTRATIVE ANOMALY (Q4 SPIKE DETECTION)
-- =========================================================

CREATE OR REPLACE VIEW fds.v_admin_anomaly AS
WITH quarterly AS (
    SELECT
        dept_id,
        EXTRACT(YEAR FROM exp_date) AS fiscal_year,
        SUM(
            CASE
                WHEN EXTRACT(MONTH FROM exp_date) <= 9
                THEN amount
                ELSE 0
            END
        ) AS q1_q3,
        SUM(
            CASE
                WHEN EXTRACT(MONTH FROM exp_date) >= 10
                THEN amount
                ELSE 0
            END
        ) AS q4
    FROM fds.fact_expenditure
    GROUP BY
        dept_id,
        EXTRACT(YEAR FROM exp_date)
)
SELECT
    q.dept_id,
    d.dept_name,
    q.fiscal_year,
    q.q1_q3,
    q.q4,
    ROUND(
        q.q4 / NULLIF(q.q1_q3,0),
        2
    ) AS surge_ratio
FROM quarterly q
JOIN fds.dim_department d
    ON q.dept_id = d.dept_id
WHERE q.q4 > q.q1_q3;

-- =========================================================
-- 8. ML FRAUD SCORE TABLE
-- =========================================================

CREATE TABLE IF NOT EXISTS fds.ml_fraud_scores (
    tx_id INT PRIMARY KEY,
    fraud_probability NUMERIC(10,6),
    predicted_fraud INT,
    actual_fraud INT
);

-- =========================================================
-- 9. ML FRAUD DATA MART
-- =========================================================

CREATE OR REPLACE VIEW fds.v_ml_mart AS
SELECT
    f.tx_id,
    f.exp_date,
    d.dept_name,
    f.vendor_name,
    f.amount,
    m.fraud_probability,
    m.predicted_fraud,
    m.actual_fraud
FROM fds.fact_expenditure f
LEFT JOIN fds.ml_fraud_scores m
    ON f.tx_id = m.tx_id
LEFT JOIN fds.dim_department d
    ON f.dept_id = d.dept_id;

-- =========================================================
-- 9. FDS FINAL DATA MART
-- =========================================================

CREATE VIEW fds.v_fds_final AS
SELECT
    f.*,
    m.fraud_probability,
    m.predicted_fraud
FROM fds.v_fds_mart f
LEFT JOIN fds.v_ml_mart m
ON f.tx_id = m.tx_id;