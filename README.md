# AdventureWorks Supply Chain & Demand Analytics (SQL)

## Overview
This repository contains a **SQL analytics case study** built on the **AdventureWorks2022** sample database.

The project focuses on **inventory and demand-related analyses** commonly found in supply chain contexts.  
It was created as a **portfolio project** to demonstrate SQL skills using business-oriented data and realistic analytical questions.

**The primary goal of this project is to demonstrate SQL proficiency**, including query structuring, use of analytical functions, and clear logic, while applying SQL to supply chain–related topics.

---

## Tech Stack
- **Database:** Microsoft SQL Server (AdventureWorks2022)
- **Query Language:** T-SQL
- **Tools:** SQL Server Management Studio (SSMS)

---

## Analytical Scope & Techniques
The project applies commonly used analytical SQL techniques, including:

- Multi-table joins across sales, inventory, purchasing, and product tables
- Common Table Expressions (CTEs) for structured query logic
- Window functions (`SUM() OVER`, `AVG() OVER`, `LAG`)
- Time-based aggregations (daily, monthly, rolling windows)
- Inventory and demand-related metrics
- Conditional logic using `CASE`
- Explicit assumptions where required due to data limitations
- Clear naming conventions and readable query structure

---

## Business Questions Addressed

### Module 1 — Inventory & Supply Chain Analytics
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

### Module 2 — Demand Analysis & Trend Exploration
- What is the daily and monthly demand pattern per product?
- How does demand evolve over time (rolling demand, month-over-month change)?
- Which products show upward, downward, or stable demand trends?
- Are there identifiable seasonality patterns in product demand?

---


## Repository Structure

```
adventureworks-supply-chain-analytics-sql/
├── README.md
├── AdventureWorks_SQL_Results.pdf
└── sql/
    ├── 01_inventory_supply_chain.sql
    └── 02_demand_planning_sales.sql
```


## How to Use
- SQL scripts are organized into **two analytical modules**:
  - **Module 1:** Inventory & Supply Chain Analytics (Tasks 1.1–1.12)
  - **Module 2:** Demand Analysis & Trend Exploration (Tasks 2.1–2.5)
- Each task includes:
  - a short description of the analytical goal,
  - a brief note on how the result can be interpreted,
  - explicit assumptions where required due to missing data.
- Queries are written in **T-SQL** and can be executed directly against the **AdventureWorks2022** database.

---

## Notes
This project prioritizes **clarity of SQL logic and analytical structure** over performance optimization.

Some calculations rely on **simplified assumptions** (e.g. holding cost rates, ordering costs, production capacity), as such values are not fully available in the AdventureWorks sample database. These assumptions are documented directly in the SQL scripts.

The repository is intended as a **SQL portfolio case study**, demonstrating the ability to analyze business-related data using structured and readable SQL queries.




