USE AdventureWorks2022;
GO

/*
============================================================
MODULE 1 — INVENTORY & SUPPLY CHAIN ANALYTICS (T-SQL)
Database: AdventureWorks2022
Scope: Tasks 1.1 – 1.12
============================================================
*/

------------------------------------------------------------
-- Task 1.1 — Inventory Snapshot
-- Goal: List all SKUs with current stock quantity in each location.
------------------------------------------------------------
SELECT
    p.ProductID,
    p.Name           AS Product_name,
    p.ProductNumber,
    l.Name           AS Location_name,
    i.Quantity
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l
    ON i.LocationID = l.LocationID
ORDER BY p.ProductID, l.Name;
GO


------------------------------------------------------------
-- Task 1.2 — Low Stock Alerts
-- Goal: Identify SKUs with stock <= threshold.
------------------------------------------------------------
SELECT
    p.ProductID,
    p.Name           AS Product_name,
    p.ProductNumber,
    l.Name           AS Location_name,
    i.Quantity,
    20               AS LowStockThreshold
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l
    ON i.LocationID = l.LocationID
WHERE i.Quantity <= 20
ORDER BY p.ProductID, l.Name;
GO


------------------------------------------------------------
-- Task 1.3 — Inventory Valuation
-- Goal: Inventory value = Quantity * StandardCost (filter out StandardCost = 0).
------------------------------------------------------------
SELECT
    p.ProductID,
    p.Name           AS Product_name,
    p.ProductNumber,
    l.Name           AS Location_name,
    i.Quantity,
    p.StandardCost,
    CAST(i.Quantity AS decimal(18,4)) * CAST(p.StandardCost AS decimal(18,4)) AS Inventory_Value
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l
    ON i.LocationID = l.LocationID
WHERE p.StandardCost > 0
ORDER BY Inventory_Value DESC;
GO


------------------------------------------------------------
-- Task 1.4 — Inventory Turnover (Last 12 Months Sales / Current Inventory)
-- Notes:
-- - Period is defined as the last 12 months from MAX(OrderDate) in the dataset.
-- - Turnover uses FLOAT/DECIMAL division to avoid integer truncation.
------------------------------------------------------------
WITH Date_Range AS (
    SELECT
        DATEADD(YEAR, -1, MAX(OrderDate)) AS StartDate,
        MAX(OrderDate)                    AS EndDate
    FROM Sales.SalesOrderHeader
),
SalesTab AS (
    SELECT
        sd.ProductID,
        p.Name,
        p.ProductNumber,
        SUM(sd.OrderQty) AS Sales_Qty_12M
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    WHERE sh.OrderDate BETWEEN (SELECT StartDate FROM Date_Range)
                          AND (SELECT EndDate   FROM Date_Range)
    GROUP BY sd.ProductID, p.Name, p.ProductNumber
),
Inventory AS (
    SELECT
        ProductID,
        SUM(Quantity) AS Inventory_Qty
    FROM Production.ProductInventory
    GROUP BY ProductID
)
SELECT
    st.ProductID,
    st.Name,
    st.ProductNumber,
    st.Sales_Qty_12M,
    i.Inventory_Qty,
    CAST(st.Sales_Qty_12M AS decimal(18,4)) / NULLIF(i.Inventory_Qty, 0) AS Turnover,
    CASE
        WHEN CAST(st.Sales_Qty_12M AS decimal(18,4)) / NULLIF(i.Inventory_Qty, 0) < 1 THEN 'Slow_Rotation_Risk'
        WHEN CAST(st.Sales_Qty_12M AS decimal(18,4)) / NULLIF(i.Inventory_Qty, 0) <= 4 THEN 'Mid_Rotation'
        ELSE 'Quick_Rotation'
    END AS Rotation
FROM SalesTab st
INNER JOIN Inventory i
    ON st.ProductID = i.ProductID
ORDER BY Turnover DESC;
GO


------------------------------------------------------------
-- Task 1.5 — Days of Supply (DoS)
-- DoS = Current Inventory / Average Daily Demand (last 30 days)
------------------------------------------------------------
WITH RangeDate AS (
    SELECT
        DATEADD(DAY, -30, MAX(OrderDate)) AS StartDate,
        MAX(OrderDate)                    AS EndDate
    FROM Sales.SalesOrderHeader
),
TotalDemand AS (
    SELECT
        sd.ProductID,
        p.Name,
        SUM(sd.OrderQty) AS Total_Qty_30D
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    WHERE sh.OrderDate BETWEEN (SELECT StartDate FROM RangeDate)
                          AND (SELECT EndDate   FROM RangeDate)
    GROUP BY sd.ProductID, p.Name
),
AvgDemand AS (
    SELECT
        ProductID,
        Name,
        Total_Qty_30D / 30.0 AS Avg_Daily_Demand
    FROM TotalDemand
),
Inventory AS (
    SELECT
        ProductID,
        SUM(Quantity) AS Inventory_Qty
    FROM Production.ProductInventory
    GROUP BY ProductID
)
SELECT
    d.ProductID,
    d.Name,
    i.Inventory_Qty,
    CAST(d.Avg_Daily_Demand AS decimal(18,4)) AS Avg_Daily_Demand,
    CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0) AS Days_of_Supply,
    CASE
        WHEN (CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0)) IS NULL THEN 'No recent demand'
        WHEN (CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0)) <= 0 THEN 'Out of stock risk'
        WHEN (CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0)) <= 7 THEN 'High stockout risk'
        WHEN (CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0)) <= 30 THEN 'Stock within limits'
        WHEN (CAST(i.Inventory_Qty AS decimal(18,4)) / NULLIF(d.Avg_Daily_Demand, 0)) <= 90 THEN 'Overstock risk'
        ELSE 'Dead stock / very high DoS'
    END AS DoS_Category
FROM AvgDemand d
INNER JOIN Inventory i
    ON d.ProductID = i.ProductID
ORDER BY Days_of_Supply ASC;
GO


------------------------------------------------------------
-- Task 1.6 — Inventory Aging
-- Proxy: ProductInventory.ModifiedDate as "last update date" of inventory record.
------------------------------------------------------------
SELECT
    i.ProductID,
    p.Name,
    CAST(i.ModifiedDate AS date) AS ModifiedDate,
    DATEDIFF(DAY, i.ModifiedDate, CAST(GETDATE() AS date)) AS Days_in_stock
FROM Production.ProductInventory i
INNER JOIN Production.Product p
    ON i.ProductID = p.ProductID
ORDER BY Days_in_stock DESC;
GO


------------------------------------------------------------
-- Task 1.7 — ABC Classification (by inventory value)
-- Logic:
-- 1) Compute inventory value per product (Quantity * StandardCost)
-- 2) Compute percent share and cumulative share (descending)
-- 3) Class A: <=80%, B: <=95%, C: rest
------------------------------------------------------------
WITH Cost_Product AS (
    SELECT
        i.ProductID,
        p.Name,
        SUM(CAST(i.Quantity AS decimal(18,4)) * CAST(p.StandardCost AS decimal(18,4))) AS Inventory_Cost,
        SUM(SUM(CAST(i.Quantity AS decimal(18,4)) * CAST(p.StandardCost AS decimal(18,4)))) OVER () AS Total_Cost
    FROM Production.ProductInventory i
    INNER JOIN Production.Product p
        ON i.ProductID = p.ProductID
    GROUP BY i.ProductID, p.Name
),
Percentage_Share AS (
    SELECT
        ProductID,
        Name,
        (Inventory_Cost / NULLIF(Total_Cost, 0)) * 100.0 AS Perc_Share
    FROM Cost_Product
    WHERE Inventory_Cost > 0
),
Cumulative AS (
    SELECT
        *,
        SUM(Perc_Share) OVER (ORDER BY Perc_Share DESC) AS Cumulative_Share
    FROM Percentage_Share
)
SELECT
    ProductID,
    Name,
    CAST(Cumulative_Share AS decimal(10,2)) AS Cum_Share_Pct,
    CASE
        WHEN Cumulative_Share <= 80 THEN 'A'
        WHEN Cumulative_Share <= 95 THEN 'B'
        ELSE 'C'
    END AS ABC_Class
FROM Cumulative
ORDER BY Cum_Share_Pct;
GO


------------------------------------------------------------
-- Task 1.8 — Safety Stock
-- SS = Z * sigma(daily demand) * sqrt(lead time)
-- Assumptions:
-- - Z = 1.65 (~95% service level)
-- - Demand variability based on last 30 days of sales
-- - Lead time from Purchasing orders (OrderDate -> ShipDate)
------------------------------------------------------------
WITH Range_Date AS (
    SELECT
        DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date,
        MAX(OrderDate)                    AS End_Date
    FROM Sales.SalesOrderHeader
),
Sales_30_Days AS (
    SELECT
        CAST(sh.OrderDate AS date) AS OrderDate,
        sd.ProductID,
        SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date)
                          AND (SELECT End_Date   FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS date), sd.ProductID
),
Daily_Stat AS (
    SELECT
        ProductID,
        AVG(CAST(Daily_Order_Qty AS float))      AS Avg_Qty,
        STDEVP(CAST(Daily_Order_Qty AS float))   AS Std_Dev
    FROM Sales_30_Days
    GROUP BY ProductID
),
Lead_Time AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS float)) AS Avg_Lead_Time
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
)
SELECT
    ds.ProductID,
    p.Name,
    ds.Avg_Qty,
    ROUND(ds.Std_Dev, 2)        AS Std_Dev,
    lt.Avg_Lead_Time,
    ROUND(1.65 * ds.Std_Dev * SQRT(lt.Avg_Lead_Time), 2) AS SafetyStock
FROM Daily_Stat ds
INNER JOIN Lead_Time lt
    ON ds.ProductID = lt.ProductID
INNER JOIN Production.Product p
    ON ds.ProductID = p.ProductID
WHERE ds.Avg_Qty IS NOT NULL
  AND lt.Avg_Lead_Time IS NOT NULL;
GO


------------------------------------------------------------
-- Task 1.9 — Reorder Point (ROP)
-- ROP = AvgDailyDemand * LeadTime + SafetyStock
------------------------------------------------------------
WITH Range_Date AS (
    SELECT
        DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date,
        MAX(OrderDate)                    AS End_Date
    FROM Sales.SalesOrderHeader
),
Sales_30_Days AS (
    SELECT
        CAST(sh.OrderDate AS date) AS OrderDate,
        sd.ProductID,
        SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date)
                          AND (SELECT End_Date   FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS date), sd.ProductID
),
Daily_Stat AS (
    SELECT
        ProductID,
        AVG(CAST(Daily_Order_Qty AS float))      AS Avg_Qty,
        STDEVP(CAST(Daily_Order_Qty AS float))   AS Std_Dev
    FROM Sales_30_Days
    GROUP BY ProductID
),
Lead_Time AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS float)) AS Avg_Lead_Time
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
)
SELECT
    ds.ProductID,
    p.Name,
    ds.Avg_Qty,
    ROUND(ds.Std_Dev, 2) AS Std_Dev,
    lt.Avg_Lead_Time,
    ROUND(1.65 * ds.Std_Dev * SQRT(lt.Avg_Lead_Time), 2) AS SafetyStock,
    ROUND((ds.Avg_Qty * lt.Avg_Lead_Time) + (1.65 * ds.Std_Dev * SQRT(lt.Avg_Lead_Time)), 2) AS ReorderPoint
FROM Daily_Stat ds
INNER JOIN Lead_Time lt
    ON ds.ProductID = lt.ProductID
INNER JOIN Production.Product p
    ON ds.ProductID = p.ProductID;
GO


------------------------------------------------------------
-- Task 1.10 — MOQ (Minimum Order Quantity) — proxy based on weekly demand and lead time in weeks
------------------------------------------------------------
WITH Range_Date AS (
    SELECT
        DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date,
        MAX(OrderDate)                    AS End_Date
    FROM Sales.SalesOrderHeader
),
Sales_30_Days AS (
    SELECT
        CAST(sh.OrderDate AS date) AS OrderDate,
        sd.ProductID,
        SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date)
                          AND (SELECT End_Date   FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS date), sd.ProductID
),
Sales_Week_ISO AS (
    SELECT
        DATEPART(YEAR, OrderDate)     AS YR,
        DATEPART(ISO_WEEK, OrderDate) AS WK,
        ProductID,
        SUM(Daily_Order_Qty) AS Sum_Week_Qty
    FROM Sales_30_Days
    GROUP BY DATEPART(YEAR, OrderDate), DATEPART(ISO_WEEK, OrderDate), ProductID
),
Sales_Week AS (
    SELECT
        ProductID,
        AVG(CAST(Sum_Week_Qty AS float)) AS Avg_Qty_Week
    FROM Sales_Week_ISO
    GROUP BY ProductID
),
Lead_Time AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS float)) / 7.0 AS Avg_LT_Weeks
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
)
SELECT
    sw.ProductID,
    p.Name,
    lt.Avg_LT_Weeks,
    sw.Avg_Qty_Week,
    CEILING(sw.Avg_Qty_Week * lt.Avg_LT_Weeks) AS MOQ
FROM Sales_Week sw
INNER JOIN Lead_Time lt
    ON sw.ProductID = lt.ProductID
INNER JOIN Production.Product p
    ON lt.ProductID = p.ProductID;
GO


------------------------------------------------------------
-- Task 1.11 — EOQ (Economic Order Quantity) — cost-optimal order quantity
-- EOQ = sqrt( (2 * D * S) / H )
-- Assumptions:
-- - OrderingCost (S) set as constant (example): 50
-- - HoldingCost (H) = 25% of StandardCost (example)
------------------------------------------------------------
WITH Range_Date AS (
    SELECT
        DATEADD(MONTH, -12, MAX(OrderDate)) AS Start_Date,
        MAX(OrderDate)                      AS End_Date
    FROM Sales.SalesOrderHeader
),
Sales_Last_Year AS (
    SELECT
        sd.ProductID,
        SUM(sd.OrderQty) AS Annual_Demand
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date)
                          AND (SELECT End_Date   FROM Range_Date)
    GROUP BY sd.ProductID
),
Product_Par AS (
    SELECT
        ProductID,
        Name,
        50.0 AS OrderingCost,
        CAST(StandardCost * 0.25 AS decimal(18,4)) AS HoldingCost
    FROM Production.Product
    WHERE StandardCost > 0
)
SELECT
    sy.ProductID,
    pp.Name,
    sy.Annual_Demand,
    pp.OrderingCost,
    pp.HoldingCost,
    CASE
        WHEN pp.HoldingCost = 0 THEN NULL
        ELSE CEILING(SQRT((2.0 * sy.Annual_Demand * pp.OrderingCost) / pp.HoldingCost))
    END AS EOQ
FROM Sales_Last_Year sy
INNER JOIN Product_Par pp
    ON sy.ProductID = pp.ProductID;
GO


------------------------------------------------------------
-- Task 1.12 — EPQ (Economic Production Quantity)
-- EPQ = sqrt( (2DS) / (H * (1 - D/P)) )
-- Assumptions:
-- - Setup cost (S) constant example: 120
-- - HoldingCost (H) = 25% of StandardCost
-- - Production capacity (P) constant example: 100000 / year
------------------------------------------------------------
WITH Range_Date AS (
    SELECT
        DATEADD(MONTH, -12, MAX(OrderDate)) AS Start_Date,
        MAX(OrderDate)                      AS End_Date
    FROM Sales.SalesOrderHeader
),
Sales_Last_Year AS (
    SELECT
        sd.ProductID,
        SUM(sd.OrderQty) AS Annual_Demand
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date)
                          AND (SELECT End_Date   FROM Range_Date)
    GROUP BY sd.ProductID
),
Product_Par AS (
    SELECT
        ProductID,
        Name,
        120.0 AS Setup_Cost,
        CAST(StandardCost * 0.25 AS decimal(18,4)) AS HoldingCost,
        100000.0 AS Annual_Prod_Capacity
    FROM Production.Product
    WHERE StandardCost > 0
)
SELECT
    sy.ProductID,
    pp.Name,
    CASE
        WHEN pp.HoldingCost <= 0
          OR sy.Annual_Demand <= 0
          OR (1.0 - (sy.Annual_Demand / pp.Annual_Prod_Capacity)) <= 0
        THEN NULL
        ELSE CEILING(
            SQRT((2.0 * sy.Annual_Demand * pp.Setup_Cost) /
                 (pp.HoldingCost * (1.0 - (sy.Annual_Demand / pp.Annual_Prod_Capacity))))
        )
    END AS EPQ
FROM Sales_Last_Year sy
INNER JOIN Product_Par pp
    ON sy.ProductID = pp.ProductID;
GO

