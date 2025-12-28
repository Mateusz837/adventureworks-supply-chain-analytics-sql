# AdventureWorks Supply Chain & Demand Analytics (SQL)

## Overview
This repository contains a **business-oriented SQL analytics case study** built on the **AdventureWorks2022** sample database.

The project focuses on **inventory control, replenishment logic, and demand planning**, reflecting the type of analyses performed daily by **supply chain planners, inventory analysts, and BI teams** in manufacturing and distribution environments.

**The goal of this project is to demonstrate SQL proficiency** by applying advanced analytical techniques to realistic supply chain and demand planning scenarios.  
The analysis emphasizes clear query structure, explicit assumptions, readable logic, and direct business applicability.

---

## Tech Stack
- **Database:** Microsoft SQL Server (AdventureWorks2022)
- **Query Language:** T-SQL
- **Tools:** SQL Server Management Studio (SSMS) / Azure Data Studio

---

## Analytical Scope & Techniques
The project applies practical analytical SQL techniques commonly used in operational and planning contexts:

- Multi-table joins across sales, inventory, purchasing, and product domains
- Common Table Expressions (CTEs) for step-by-step analytical logic
- Window functions (`SUM() OVER`, `AVG() OVER`, `LAG`)
- Time-based aggregations (daily, monthly, rolling windows)
- Inventory and demand planning KPIs
- Variability- and lead-time-driven calculations
- Statistical measures (average, standard deviation)
- Conditional logic using `CASE`
- Explicit handling of assumptions where source data is incomplete
- Business-driven naming conventions and readable query structure

---

## Business Questions Addressed

### Module 1 — Inventory & Supply Chain Analytics
- What is the current inventory position by product and warehouse location?
- Which SKUs are at risk of stockout due to low on-hand quantity?
- How much working capital is currently tied up in inventory?
- Which products rotate slowly versus quickly (Inventory Turnover)?
- How long will current stock last at the current demand rate (Days of Supply)?
- Which items show signs of aging or potential obsolescence?
- Which SKUs account for the majority of inventory value (ABC Classification)?
- How much safety stock is required given demand and lead-time variability?
- When should replenishment be triggered to avoid shortages (Reorder Point)?
- What order or production quantities minimize total cost (MOQ, EOQ, EPQ)?

### Module 2 — Demand Planning & Sales Analytics
- What is the daily and monthly demand pattern per product?
- How does demand evolve over time (rolling demand, month-over-month change)?
- Which products show upward, downward, or stable demand trends?
- Are there identifiable seasonality patterns in product demand?
- When do peak and off-season periods occur for individual SKUs?

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
  - a clear business purpose,
  - a short explanation of how the result is used in practice,
  - explicit assumptions where required due to data limitations.
- `AdventureWorks_SQL_Results.pdf` presents selected query outputs with short operational interpretations.
- All queries are written in **T-SQL** and can be executed directly against the **AdventureWorks2022** database.

---

## Notes
This project prioritizes **analytical clarity and business realism** over production-level performance tuning.

Some calculations (e.g. safety stock parameters, ordering costs, holding cost rates, production capacity) rely on **explicit assumptions**, as such values are not fully available in the AdventureWorks sample database. These assumptions are clearly documented to mirror real-world analytical decision-making.

The repository is intended as a **portfolio case study**, demonstrating the ability to translate business questions into structured SQL analyses with clear and interpretable results.






