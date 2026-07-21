# Email User Activity Analytics

Analytical dataset and SQL transformation pipeline built to evaluate account creation trends, email marketing engagement (sends, opens, link clicks), and user behavior across top global markets.

---

## 📌 Business Goal
The objective of this project is to consolidate fragmented data sources (Google Analytics sessions, user profile statuses, and email activity logs) into a unified dataset. This enables stakeholders to:
* Compare user activity and email performance across different countries.
* Identify top-performing markets based on account volume and messaging activity.
* Segment users by email intervals (`send_interval`), account verification status (`is_verified`), and churn status (`is_unsubscribed`).

---

## 🛠️ Data Transformation & SQL Logic

The core query is written in **Google BigQuery SQL** using Common Table Expressions (CTEs) and Window Functions across a multi-stage process:

1. **Dual-Path Aggregation (`base` CTE):**
   * **Account Metrics:** Counts unique accounts created within specific dimension slices.
   * **Email Metrics:** Calculates message interaction counts (`sent_msg`, `open_msg`, `visit_msg`) based on message IDs (`id_message`).
   * *Both streams are merged via `UNION ALL` to prevent row multiplication and maintain accurate counts.*

2. **Dimension Consolidation (`agregations` CTE):**
   * Aggregates accounts and email metrics across 5 key grouping dimensions: `date`, `country`, `send_interval`, `is_verified`, and `is_unsubscribed`.

3. **Country-Level Totals (`totals` CTE):**
   * Uses Window Functions (`SUM() OVER(PARTITION BY country)`) to compute overall country-wide volumes for created accounts (`total_country_account_cnt`) and sent messages (`total_country_sent_cnt`).

4. **Market Ranking & Filtering (`ranks` CTE & Final Output):**
   * Applies `DENSE_RANK()` to order countries by total accounts and total sent emails.
   * Filters the final dataset to retain only the **Top 10 countries** in either account volume or email activity.

---

## 📊 Output Schema

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `datee` | DATE / TIMESTAMP | Date of account creation or email send event |
| `country` | STRING | Country derived from session parameters |
| `sent_intervall` | STRING / INT | Account-defined email sending frequency |
| `is_verified` | BOOL | Verification status of the account |
| `is_unsubscribed` | BOOL | Email subscription status |
| `account_cnt` | INT64 | Number of created accounts |
| `sent_msg` | INT64 | Total emails sent |
| `open_msg` | INT64 | Total emails opened |
| `visit_msg` | INT64 | Total link clicks / visits from emails |
| `total_country_account_cnt` | INT64 | Country-wide total accounts created |
| `total_country_sent_cnt` | INT64 | Country-wide total emails sent |
| `rank_total_country_account_cnt` | INT64 | Country rank by total account volume |
| `rank_total_country_sent_cnt` | INT64 | Country rank by total sent emails volume |

---

## 🚀 Tech Stack & SQL Techniques
* **Database Engine:** Google BigQuery
* **Key SQL Features:** Common Table Expressions (CTEs), `UNION ALL`, `LEFT JOIN` / `INNER JOIN`, Aggregate Functions (`COUNT(DISTINCT)`), Analytic Window Functions (`SUM() OVER`, `DENSE_RANK()`).
