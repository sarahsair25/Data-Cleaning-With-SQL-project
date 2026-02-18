-- ============================================================
--   DATA CLEANING WITH SQL - Complete Project
--   Dataset: customer_orders (simulated e-commerce data)
--   Author: Your Name
-- ============================================================

-- ============================================================
-- STEP 0: CREATE RAW TABLE & LOAD SAMPLE DATA
-- ============================================================

CREATE TABLE raw_customer_orders (
    order_id        VARCHAR(50),
    customer_name   VARCHAR(100),
    email           VARCHAR(100),
    phone           VARCHAR(30),
    order_date      VARCHAR(30),   -- stored as text (dirty)
    product         VARCHAR(100),
    quantity        VARCHAR(20),   -- stored as text (dirty)
    unit_price      VARCHAR(20),   -- stored as text (dirty)
    city            VARCHAR(50),
    country         VARCHAR(50),
    status          VARCHAR(30)
);

-- Insert messy sample data
INSERT INTO raw_customer_orders VALUES
('ORD-001', 'Alice Johnson',    'alice@example.com',      '(312) 555-1234', '2024-01-15', 'Laptop',   '1',  '999.99',  'Chicago',    'USA',           'Completed'),
('ORD-002', 'BOB SMITH',        'bob@EXAMPLE.COM',        '312.555.5678',   '15-01-2024', 'Mouse',    '2',  '25.50',   'chicago',    'usa',           'completed'),
('ORD-003', '',                 'carol@example.com',      NULL,             '2024/01/16', 'Keyboard', '3',  '$45.00',  'New York',   'United States', 'PENDING'),
('ORD-004', '  David Lee  ',    'david@@example.com',     '5555555',        '2024-01-17', 'Monitor',  '-1', '350.00',  'Los Angeles','US',            'Shipped'),
('ORD-005', 'Eve Torres',       'eve@example.com',        '+1-800-555-0199','January 18, 2024','Webcam','0','89.99',  'Houston',    'USA',           'Cancelled'),
('ORD-006', 'Frank N/A',        'frank@example.com',      '(214)5559876',   '2024-01-19', 'Headset',  '2',  '75.00',  'Dallas',     'USA',           'Completed'),
('ORD-007', 'Grace Kim',        'grace@example.com',      '7135550123',     '2024-01-20', 'Laptop',   '1',  '999.99', 'Houston',    'USA',           'Completed'),
('ORD-001', 'Alice Johnson',    'alice@example.com',      '(312) 555-1234', '2024-01-15', 'Laptop',   '1',  '999.99', 'Chicago',    'USA',           'Completed'),  -- duplicate
('ORD-008', 'Hank   Morris',    'hank@example.com',       '2125551234',     '2024-01-21', 'Tablet',   '2',  'N/A',    'New York',   'USA',           'Pending'),
('ORD-009', NULL,               'unknown@example.com',    '0000000000',     '2024-01-22', 'Charger',  '5',  '19.99',  'Phoenix',    'USA',           'Processing'),
('ORD-010', 'Ivy Chen',         'ivy@example.com',        '4155558888',     '2024-01-23', 'SSD',      '1',  '129.99', 'San Francisco','USA',         'Shipped');


-- ============================================================
-- STEP 1: EXPLORE THE DATA
-- ============================================================

-- 1a. Total row count
SELECT COUNT(*) AS total_rows FROM raw_customer_orders;

-- 1b. Spot NULL or blank values per column
SELECT
    SUM(CASE WHEN order_id       IS NULL OR order_id = ''       THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_name  IS NULL OR customer_name = ''  THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN email          IS NULL OR email = ''          THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN phone          IS NULL OR phone = ''          THEN 1 ELSE 0 END) AS null_phone,
    SUM(CASE WHEN order_date     IS NULL OR order_date = ''     THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN quantity       IS NULL OR quantity = ''       THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN unit_price     IS NULL OR unit_price = ''     THEN 1 ELSE 0 END) AS null_unit_price
FROM raw_customer_orders;

-- 1c. Check duplicate order IDs
SELECT order_id, COUNT(*) AS cnt
FROM raw_customer_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 1d. Distinct status values (spot inconsistencies)
SELECT DISTINCT LOWER(TRIM(status)) AS status_values
FROM raw_customer_orders;

-- 1e. Distinct country values (spot inconsistencies)
SELECT DISTINCT country FROM raw_customer_orders;


-- ============================================================
-- STEP 2: CREATE STAGING TABLE
-- ============================================================

CREATE TABLE staging_customer_orders AS
SELECT * FROM raw_customer_orders;

-- Always work on a staging copy — never alter raw data!


-- ============================================================
-- STEP 3: REMOVE EXACT DUPLICATES
-- ============================================================

-- Identify duplicates using ROW_NUMBER
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, customer_name, email, order_date, product
               ORDER BY order_id
           ) AS rn
    FROM staging_customer_orders
)
DELETE FROM staging_customer_orders
WHERE order_id IN (
    SELECT order_id FROM deduped WHERE rn > 1
);

-- Verify
SELECT COUNT(*) AS rows_after_dedup FROM staging_customer_orders;


-- ============================================================
-- STEP 4: STANDARDIZE TEXT FIELDS
-- ============================================================

-- 4a. Trim whitespace from customer_name
UPDATE staging_customer_orders
SET customer_name = TRIM(customer_name);

-- 4b. Title-case customer names (PostgreSQL example using initcap)
UPDATE staging_customer_orders
SET customer_name = INITCAP(LOWER(customer_name));

-- 4c. Lowercase email addresses
UPDATE staging_customer_orders
SET email = LOWER(TRIM(email));

-- 4d. Normalize status to Title Case
UPDATE staging_customer_orders
SET status = INITCAP(LOWER(TRIM(status)));

-- 4e. Normalize country to consistent values
UPDATE staging_customer_orders
SET country = 'USA'
WHERE LOWER(TRIM(country)) IN ('us', 'united states', 'united states of america', 'usa');

-- 4f. Normalize city capitalization
UPDATE staging_customer_orders
SET city = INITCAP(LOWER(TRIM(city)));

-- Verify
SELECT customer_name, email, status, country, city
FROM staging_customer_orders
LIMIT 10;


-- ============================================================
-- STEP 5: HANDLE NULL / MISSING VALUES
-- ============================================================

-- 5a. Replace NULL customer_name with 'Unknown'
UPDATE staging_customer_orders
SET customer_name = 'Unknown'
WHERE customer_name IS NULL OR TRIM(customer_name) = '';

-- 5b. Replace placeholder names like 'N/A'
UPDATE staging_customer_orders
SET customer_name = 'Unknown'
WHERE LOWER(customer_name) LIKE '%n/a%';

-- 5c. Flag invalid emails (no @ or multiple @)
ALTER TABLE staging_customer_orders ADD COLUMN email_valid BOOLEAN DEFAULT TRUE;

UPDATE staging_customer_orders
SET email_valid = FALSE
WHERE email NOT LIKE '%@%.%'
   OR LENGTH(email) - LENGTH(REPLACE(email, '@', '')) <> 1;

-- 5d. Replace invalid/placeholder phone with NULL for clarity
UPDATE staging_customer_orders
SET phone = NULL
WHERE phone IN ('0000000000', 'N/A', 'n/a', '')
   OR phone IS NULL;

-- 5e. Handle N/A unit_price — set to NULL
UPDATE staging_customer_orders
SET unit_price = NULL
WHERE LOWER(TRIM(unit_price)) = 'n/a' OR TRIM(unit_price) = '';

-- Verify nulls/flags
SELECT customer_name, email, email_valid, phone, unit_price
FROM staging_customer_orders;


-- ============================================================
-- STEP 6: FIX DATA TYPES & FORMAT CONSISTENCY
-- ============================================================

-- 6a. Standardize phone numbers → digits only (PostgreSQL REGEXP_REPLACE)
UPDATE staging_customer_orders
SET phone = REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
WHERE phone IS NOT NULL;

-- Keep only 10-digit US numbers; nullify others
UPDATE staging_customer_orders
SET phone = NULL
WHERE phone IS NOT NULL AND LENGTH(phone) NOT IN (10, 11);

-- 6b. Clean unit_price: remove $ and spaces
UPDATE staging_customer_orders
SET unit_price = REPLACE(REPLACE(unit_price, '$', ''), ' ', '')
WHERE unit_price IS NOT NULL;

-- 6c. Validate quantity is a positive integer
UPDATE staging_customer_orders
SET quantity = NULL
WHERE CAST(quantity AS INTEGER) <= 0;


-- ============================================================
-- STEP 7: STANDARDIZE DATE FORMATS
-- ============================================================

-- 6a. Add a clean date column
ALTER TABLE staging_customer_orders ADD COLUMN order_date_clean DATE;

-- 6b. Parse various date formats using CASE
UPDATE staging_customer_orders
SET order_date_clean =
    CASE
        -- Format: YYYY-MM-DD
        WHEN order_date ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TO_DATE(order_date, 'YYYY-MM-DD')
        -- Format: DD-MM-YYYY
        WHEN order_date ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(order_date, 'DD-MM-YYYY')
        -- Format: YYYY/MM/DD
        WHEN order_date ~ '^\d{4}/\d{2}/\d{2}$'
            THEN TO_DATE(order_date, 'YYYY/MM/DD')
        -- Format: Month DD, YYYY  (e.g., January 18, 2024)
        WHEN order_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
            THEN TO_DATE(order_date, 'Month DD, YYYY')
        ELSE NULL
    END;

-- Check rows where date parsing failed
SELECT order_id, order_date, order_date_clean
FROM staging_customer_orders
WHERE order_date_clean IS NULL;


-- ============================================================
-- STEP 8: VALIDATE BUSINESS RULES
-- ============================================================

-- 8a. Quantity must be > 0
SELECT order_id, quantity
FROM staging_customer_orders
WHERE CAST(quantity AS INTEGER) <= 0 OR quantity IS NULL;

-- 8b. Price must be positive
SELECT order_id, unit_price
FROM staging_customer_orders
WHERE CAST(unit_price AS NUMERIC) <= 0 OR unit_price IS NULL;

-- 8c. Valid status values
SELECT DISTINCT status FROM staging_customer_orders;

-- Nullify invalid statuses
UPDATE staging_customer_orders
SET status = 'Unknown'
WHERE status NOT IN ('Completed','Pending','Shipped','Cancelled','Processing');

-- 8d. Future date check
SELECT order_id, order_date_clean
FROM staging_customer_orders
WHERE order_date_clean > CURRENT_DATE;


-- ============================================================
-- STEP 9: CREATE FINAL CLEAN TABLE
-- ============================================================

CREATE TABLE clean_customer_orders AS
SELECT
    order_id,
    customer_name,
    email,
    email_valid,
    phone,
    order_date_clean                        AS order_date,
    product,
    CAST(quantity AS INTEGER)               AS quantity,
    CAST(unit_price AS NUMERIC(10,2))       AS unit_price,
    CAST(quantity AS INTEGER)
        * CAST(unit_price AS NUMERIC(10,2)) AS total_amount,
    city,
    country,
    status
FROM staging_customer_orders
WHERE order_date_clean IS NOT NULL      -- exclude unparseable dates
  AND quantity IS NOT NULL             -- exclude invalid quantities
  AND unit_price IS NOT NULL;          -- exclude unknown prices


-- ============================================================
-- STEP 10: FINAL VALIDATION REPORT
-- ============================================================

-- Summary stats
SELECT
    COUNT(*)                                        AS total_orders,
    COUNT(DISTINCT customer_name)                   AS unique_customers,
    SUM(total_amount)                               AS total_revenue,
    ROUND(AVG(total_amount), 2)                     AS avg_order_value,
    MIN(order_date)                                 AS earliest_order,
    MAX(order_date)                                 AS latest_order,
    SUM(CASE WHEN email_valid = FALSE THEN 1 END)   AS invalid_emails,
    SUM(CASE WHEN phone IS NULL THEN 1 END)         AS missing_phones
FROM clean_customer_orders;

-- Orders by status
SELECT status, COUNT(*) AS count, SUM(total_amount) AS revenue
FROM clean_customer_orders
GROUP BY status
ORDER BY count DESC;

-- Orders by country
SELECT country, COUNT(*) AS count
FROM clean_customer_orders
GROUP BY country
ORDER BY count DESC;

-- Data quality score
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN email_valid THEN 1 ELSE 0 END) / COUNT(*),
    2) AS email_quality_pct,
    ROUND(
        100.0 * SUM(CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
    2) AS phone_completeness_pct
FROM clean_customer_orders;


-- ============================================================
-- END OF PROJECT
-- ============================================================
