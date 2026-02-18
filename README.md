
<img width="1536" height="1024" alt="SQL project" src="https://github.com/user-attachments/assets/dd5a6f63-cb63-49b9-a1ad-ff225d335df7" />


![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791)
![pgAdmin](https://img.shields.io/badge/Tool-pgAdmin%204-success)
![Portfolio](https://img.shields.io/badge/Portfolio-Data%20Analyst-orange)


**🧹 Data Cleaning with SQL**

A hands-on SQL project demonstrating professional data cleaning techniques on a simulated e-commerce customer orders dataset.


**📌 Project Overview**
Raw data is rarely clean. This project walks through a complete, production-style data cleaning pipeline using pure SQL — from raw messy data all the way to a validated, analysis-ready table. Every step is documented and reproducible.
Dataset: Simulated customer_orders table (~11 rows with intentional data quality issues)
Database: PostgreSQL (syntax adaptable to MySQL / SQLite with minor changes)

### 🎯 What This Project Covers###

| # | Step | Description |
| :--- | :--- | :--- |
| 0 | Raw Data Setup | Create table & insert intentionally messy records |
| 1 | Exploratory Analysis | Count nulls, spot duplicates, audit distinct values |
| 2 | Staging Layer | Work on a copy — never alter raw data |
| 3 | Duplicate Removal | Use `ROW_NUMBER()` window function to remove dupes |
| 4 | Text Standardization | TRIM, LOWER, INITCAP, normalize country/status |
| 5 | Null Handling | Replace NULLs, flag invalid emails, nullify placeholders |
| 6 | Data Type Fixes | Clean phone numbers, strip $ from prices, validate quantities |
| 7 | Date Normalization | Parse 4 mixed date formats into a consistent DATE column |
| 8 | Business Rule Validation | Enforce positive quantities, valid statuses, no future dates |
| 9 | Final Clean Table | Create `clean_customer_orders` with computed total_amount |
| 10 | Quality Report | Summary stats, status breakdown, data quality score (%) |




🚀 Getting Started
Prerequisites

PostgreSQL 13+ (or adapt for MySQL/SQLite)
psql CLI or pgAdmin / DBeaver


# Connect to your database and run
data_cleaning_project.sql in your GUI tool and run it section by section.

**🧪 Data Quality Issues Addressed**
The raw dataset intentionally contains the following problems:

✅ Duplicate rows — same order_id inserted twice 

✅ Inconsistent casing — "BOB SMITH", "chicago", "completed"

✅ Inconsistent country names — "US", "United States", "usa", "USA"
✅ Mixed date formats — YYYY-MM-DD, DD-MM-YYYY, YYYY/MM/DD, Month DD, YYYY
✅ Invalid emails — david@@example.com (double @)
✅ Messy phone numbers — (312) 555-1234, 312.555.5678, +1-800-555-0199
✅ Placeholder values — "N/A", "0000000000", "n/a" in price/phone
✅ Invalid quantities — -1, 0
✅ Currency symbols in price — "$45.00" stored as text
✅ NULL / blank names — missing customer_name
✅ Inconsistent whitespace — "  David Lee  ", "Hank   Morris"


**📊 Key SQL Concepts Used**

ROW_NUMBER() window function for deduplication
REGEXP_REPLACE() for phone number normalization
CASE WHEN for multi-format date parsing
TO_DATE() for string-to-date conversion
INITCAP() / LOWER() / TRIM() for text standardization
CAST() for type conversion
Computed columns (quantity * unit_price)
Aggregation for data quality scoring


📈 Sample Output — Final Quality Report
total_orders | unique_customers | total_revenue | avg_order_value | invalid_emails | missing_phones
-------------|------------------|---------------|-----------------|----------------|---------------
      9      |        9         |   3,584.82    |     398.31      |       1        |       2

**💡 Lessons Learned**

Never modify raw data — always use a staging table
Explore before cleaning — understand distributions first
Document every assumption — especially how you handle ambiguous formats
Validate after each step — don't wait until the end to catch errors
Build a quality scorecard — quantify improvement, not just describe it

**🛠 Adapting for MySQL / SQLite**

| PostgreSQL | MySQL | SQLite |
| :--- | :--- | :--- |
| `INITCAP()` | Custom or `CONCAT(UPPER(LEFT(col,1)), LOWER(SUBSTR(col,2)))` | Same as MySQL |
| `REGEXP_REPLACE()` | `REGEXP_REPLACE()` (MySQL 8+) | Not natively supported |
| `TO_DATE()` | `STR_TO_DATE()` | `DATE()` |

📄 License
MIT License — free to use, adapt, and share.

🙋 Author 
Sarah Sair 

If you found this useful, please ⭐ the repo!
