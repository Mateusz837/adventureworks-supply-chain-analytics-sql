# AdventureWorks Inventory Analytics (SQL)

## Overview
This repository contains a **SQL analytics case study** built on the **AdventureWorks2022** sample database.

The project focuses primarily on **inventory-related analyses**, with selected demand-based calculations used as supporting inputs.  
It was created as a **portfolio project** to demonstrate SQL skills using business-oriented data and common inventory analytics scenarios.

**The primary goal of this project is to demonstrate SQL proficiency**, including query structuring, use of analytical functions, and clear logic, applied to inventory-focused analytical problems.

---

## Tech Stack
- **Database:** Microsoft SQL Server (AdventureWorks2022)
- **Query Language:** T-SQL
- **Tools:** SQL Server Management Studio (SSMS)

---

## Analytical Scope & Techniques
The project applies commonly used analytical T-SQL techniques, including:

- Multi-table joins and aggregations
- Common Table Expressions (CTEs)
- Window functions (`SUM() OVER`, `AVG() OVER`, `LAG`)
- Time-based aggregations (daily, monthly, rolling windows)
- Rolling calculations (e.g. 3-month rolling demand)
- Statistical functions (e.g. standard deviation via `STDEVP`)
- Conditional logic using `CASE`
- Defensive calculations (e.g. divide-by-zero handling, explicit casting to avoid integer division)

---

## Business Questions Addressed

### Module 1 — Inventory Analytics
- What is the current inventory position by product and warehouse location?
- Which SKUs are at risk of stockout due to low on-hand quantity?
- How much working capital is tied up in inventory?
- Which products rotate slowly versus quickly (Inventory Turnover)?
- How long will current stock last at the current demand rate (Days of Supply)?
- Which items show signs of aging or potential obsolescence?
- Which SKUs account for the majority of inventory value (ABC Classification)?
- How much safety stock is required given demand and lead-time variability?
- When should replenishment be triggered to avoid shortages (Reorder Point)?
- What order or production quantities minimize total cost (MOQ, EOQ, EPQ)?

### Module 2 — Demand Analysis 
- What is the daily and monthly demand pattern per product?
- How does demand evolve over time (rolling demand, month-over-month change)?
- Which products show upward, downward, or stable demand trends?
- Are there identifiable seasonality patterns in product demand?

---

## Repository Structure

    adventureworks-inventory-analytics-sql/
    ├── README.md
    ├── AdventureWorks_SQL_Results.pdf
    └── sql/
        ├── 01_inventory_analytics.sql
        └── 02_sales_demand_patterns.sql

---

## How to Use
- SQL scripts are organized into **two analytical modules**:
  - **Module 1:** Inventory Analytics (Tasks 1.1–1.12)
  - **Module 2:** Demand Analysis (Supporting) (Tasks 2.1–2.5)
- Each task includes:
  - a short description of the analytical goal,
  - a brief note on how the result can be interpreted,
  - explicit assumptions where required due to missing data.
- Queries are written in **T-SQL** and can be executed directly against the **AdventureWorks2022** database.

---

## Notes
This project prioritizes **clarity of SQL logic and analytical structure** over performance optimization.

Some calculations rely on **simplified assumptions** (e.g. holding cost rates, ordering costs, production capacity), as such values are not fully available in the AdventureWorks sample database. These assumptions are documented directly in the SQL scripts.

The repository is intended as a **SQL portfolio case study**, demonstrating the ability to analyze inventory-related business data using structured and readable SQL queries.



