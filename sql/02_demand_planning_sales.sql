USE AdventureWorks2022;   

/* 
============================================================
MODULE 2 — DEMAND PLANNING & SALES ANALYTICS (T-SQL)
Database: AdventureWorks2022
Scope: Tasks 2.1 – 2.5
============================================================
*/

-- Task 2.1 — Daily Demand Calculation
-- Business purpose: Calculate daily demand per product based on sales orders.
-- How this helps: Provides a granular demand signal used for short-term planning, variability analysis, safety stock, and demand forecasting.

SELECT
    sd.ProductID, p.Name, CAST(sh.OrderDate AS DATE) AS OrderDate, SUM(sd.OrderQty) AS Order_Qty
FROM Sales.SalesOrderDetail sd
INNER JOIN Sales.SalesOrderHeader sh
    ON sd.SalesOrderID = sh.SalesOrderID
INNER JOIN Production.Product p
    ON sd.ProductID = p.ProductID
GROUP BY CAST(sh.OrderDate AS DATE), sd.ProductID, p.Name
ORDER BY OrderDate, sd.ProductID;

-- Task 2.2 — Monthly Demand
-- Business purpose: Aggregate product demand at a monthly level to identify longer-term patterns.
-- How this helps: Supports capacity planning and inventory policy decisions by smoothing daily noise and enabling trend/seasonality analysis.

SELECT
    sd.ProductID, p.Name, DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1) AS MonthDate, SUM(sd.OrderQty) AS Monthly_Qty
FROM Sales.SalesOrderDetail sd
INNER JOIN Sales.SalesOrderHeader sh
    ON sd.SalesOrderID = sh.SalesOrderID
INNER JOIN Production.Product p
    ON sd.ProductID = p.ProductID
GROUP BY DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1), sd.ProductID, p.Name
ORDER BY MonthDate, sd.ProductID;

-- Task 2.3 — Rolling 3-Month Demand
-- Business purpose: Calculate rolling 3-month demand per product to smooth short-term fluctuations.
-- How this helps: Helps planners identify underlying demand trends while reducing month-to-month volatility for better forecasting and planning.

WITH Monthly_Demand AS (
    SELECT
        sd.ProductID, p.Name,
        DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1) AS MonthDate,
        SUM(sd.OrderQty) AS Monthly_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    GROUP BY DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1), sd.ProductID, p.Name
)
SELECT
    ProductID, Name, MonthDate, Monthly_Qty,
    SUM(Monthly_Qty) OVER (
        PARTITION BY ProductID
        ORDER BY MonthDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling_3M_Demand
FROM Monthly_Demand
ORDER BY ProductID, MonthDate;

-- Task 2.4 — Trend Analysis (Month-over-Month)
-- Business purpose: Detect demand direction changes by measuring month-over-month (MoM) quantity shifts per product.
-- How this helps: Flags products with accelerating or declining demand, supporting proactive replenishment and inventory adjustments.

WITH Monthly_Demand AS (
    SELECT
        sd.ProductID, p.Name,
        DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1) AS MonthDate,
        SUM(sd.OrderQty) AS Monthly_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    GROUP BY DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1), sd.ProductID, p.Name
),
MoM_Change AS (
    SELECT
        ProductID, Name, MonthDate, Monthly_Qty,
        LAG(Monthly_Qty) OVER (PARTITION BY ProductID ORDER BY MonthDate) AS Prev_Month_Qty,
        Monthly_Qty - LAG(Monthly_Qty) OVER (PARTITION BY ProductID ORDER BY MonthDate) AS MoM_Change
    FROM Monthly_Demand
)
SELECT
    ProductID, Name, MonthDate, Monthly_Qty, Prev_Month_Qty, MoM_Change,
    CASE WHEN MoM_Change IS NULL THEN 'No trend yet'
         WHEN MoM_Change = 0 THEN 'Stable'
         WHEN MoM_Change < 0 THEN 'Downward Trend'
         WHEN MoM_Change > 0 THEN 'Upward Trend'
    END AS Trend_Label
FROM MoM_Change
ORDER BY ProductID, MonthDate;

-- Task 2.5 — Seasonality Index
-- Business purpose: Measure seasonal demand patterns by comparing monthly demand to the product’s average demand level.
-- How this helps: Identifies peak and off-season periods, enabling better inventory positioning, capacity planning, and promotion timing.
-- Assumption: Seasonality index is calculated as Monthly Demand / Average Monthly Demand per product, since no predefined seasonality indicators exist in AdventureWorks.

WITH Monthly_Demand AS (
    SELECT
        sd.ProductID, p.Name,
        DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1) AS MonthDate,
        SUM(sd.OrderQty) AS Monthly_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    GROUP BY DATEFROMPARTS(YEAR(sh.OrderDate), MONTH(sh.OrderDate), 1), sd.ProductID, p.Name
),
Avg_Monthly_Demand AS (
    SELECT ProductID, Name, AVG(CAST(Monthly_Qty AS FLOAT)) AS Avg_Monthly_Qty
    FROM Monthly_Demand
    GROUP BY ProductID, Name
),
Seasonality_Index AS (
    SELECT
        md.ProductID, md.Name, md.MonthDate, md.Monthly_Qty, amd.Avg_Monthly_Qty,
        CAST(md.Monthly_Qty / amd.Avg_Monthly_Qty AS DECIMAL(10,2)) AS Seasonality_Index
    FROM Monthly_Demand md
    INNER JOIN Avg_Monthly_Demand amd
        ON md.ProductID = amd.ProductID
)
SELECT
    ProductID, Name, MonthDate, Monthly_Qty, Avg_Monthly_Qty, Seasonality_Index,
    CASE WHEN Seasonality_Index >= 1.20 THEN 'Strong Peak Season'
         WHEN Seasonality_Index BETWEEN 1.05 AND 1.20 THEN 'Above Normal'
         WHEN Seasonality_Index BETWEEN 0.95 AND 1.05 THEN 'Normal Demand'
         WHEN Seasonality_Index BETWEEN 0.80 AND 0.95 THEN 'Below Normal'
         WHEN Seasonality_Index < 0.80 THEN 'Off-Season'
    END AS Season_Label
FROM Seasonality_Index
ORDER BY ProductID, MonthDate;




