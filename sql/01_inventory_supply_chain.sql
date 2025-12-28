USE AdventureWorks2022;
GO

/*
============================================================
MODULE 1 — INVENTORY & SUPPLY CHAIN ANALYTICS (T-SQL)
Database: AdventureWorks2022
Scope: Tasks 1.1 – 1.12
============================================================
*/

-- Task 1.1 — Inventory Snapshot
-- Business purpose: Provide a complete view of current inventory levels by product and warehouse location.

SELECT
    p.ProductID, p.Name AS Product_name, p.ProductNumber, l.Name AS Location_name, i.Quantity
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l
    ON i.LocationID = l.LocationID
ORDER BY p.ProductID, l.Name;

-- Task 1.2 — Low Stock Alerts
-- Business purpose: Identify SKUs at risk of stockout by flagging inventory levels below a defined threshold.
-- How this helps: Supports replenishment planning (purchase/production/transfers) to prevent lost sales and maintain service level.


SELECT
    p.ProductID, p.Name AS Product_name, p.ProductNumber, l.Name AS Location_name, i.Quantity,
    20 AS LowStockThreshold
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l
    ON i.LocationID = l.LocationID
WHERE i.Quantity <= 20
ORDER BY i.Quantity ASC, p.Name ASC;

-- Task 1.3 — Inventory Valuation
-- Business purpose: Calculate the monetary value of current inventory at each warehouse/location.
-- How this helps: Shows where capital is tied up in stock, helping prioritize reduction of overstock and focus on the highest-value SKUs/locations.

SELECT
    p.ProductID, p.Name as Product_name, p.ProductNumber, l.Name as Location_name, i.Quantity,
    p.StandardCost, p.StandardCost * i.Quantity AS Inventory_Value
FROM Production.ProductInventory AS i
INNER JOIN Production.Product AS p 
    ON p.ProductID = i.ProductID
INNER JOIN Production.Location AS l 
    ON i.LocationID = l.LocationID
WHERE p.StandardCost > 0
ORDER BY Inventory_Value DESC;

-- Task 1.4 — Inventory Turnover
-- Business purpose: Measure how many times inventory is sold and replenished over a year.
-- How this helps: Highlights slow-moving vs fast-rotating SKUs to optimize replenishment, reduce overstock, and improve working capital.
-- Assumption: Uses last 12 months sales vs current inventory because AdventureWorks does not provide historical inventory snapshots.

WITH Date_Range AS (
    SELECT DATEADD(YEAR, -1, MAX(OrderDate)) AS StartDate, MAX(OrderDate) AS EndDate
    FROM Sales.SalesOrderHeader
),
SalesTab AS (
    SELECT sd.ProductID, p.Name, p.ProductNumber, SUM(sd.OrderQty) AS Total_Qt
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    WHERE sh.OrderDate BETWEEN (SELECT StartDate FROM Date_Range) AND (SELECT EndDate FROM Date_Range)
    GROUP BY sd.ProductID, p.Name, p.ProductNumber
),
Inventory AS (
    SELECT ProductID, SUM(Quantity) AS Inventory_QT
    FROM Production.ProductInventory
    GROUP BY ProductID
),
Turnover_Tab AS (
    SELECT st.ProductID, st.Name, st.ProductNumber, st.Total_Qt AS Sales_Qty, i.Inventory_QT,
           CASE WHEN i.Inventory_QT = 0 THEN NULL
                ELSE CAST(st.Total_Qt / i.Inventory_QT AS DECIMAL(10,2))
           END AS Turnover
    FROM SalesTab st
    INNER JOIN Inventory i
        ON st.ProductID = i.ProductID
)
SELECT
    ProductID, Name, ProductNumber, Sales_Qty, Inventory_QT, Turnover,
    CASE WHEN Turnover < 1 THEN 'Slow_Rotation_Risk'
         WHEN Turnover <= 4 THEN 'Mid_Rotation'
         WHEN Turnover > 4 THEN 'Quick_Rotation'
    END AS Rotation
FROM Turnover_Tab
ORDER BY Turnover DESC;

-- Task 1.5 — Days of Supply (DoS)
-- Business purpose: Estimate how many days current inventory will last at the current sales rate.
-- How this helps: Helps prevent stockouts and overstock by prioritizing replenishment decisions based on consumption speed.
-- Assumption: Average daily demand is calculated from the last 30 days of sales because a longer, cleaner demand history is not provided as a ready KPI in AdventureWorks.

WITH RangeDate AS (
    SELECT DATEADD(DAY, -30, MAX(OrderDate)) AS StartDate, MAX(OrderDate) AS EndDate
    FROM Sales.SalesOrderHeader
),
TotalDemand AS (
    SELECT sd.ProductID, p.Name, SUM(sd.OrderQty) AS Total_Qt
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    INNER JOIN Production.Product p
        ON sd.ProductID = p.ProductID
    WHERE sh.OrderDate BETWEEN (SELECT StartDate FROM RangeDate) AND (SELECT EndDate FROM RangeDate)
    GROUP BY sd.ProductID, p.Name
),
AVG_Demand AS (
    SELECT ProductID, Name, Total_Qt / 30.0 AS AVG_Daily_Demand
    FROM TotalDemand
),
Inventory AS (
    SELECT ProductID, SUM(Quantity) AS Inventory_Qt
    FROM Production.ProductInventory
    GROUP BY ProductID
),
DaysOfSupply AS (
    SELECT d.ProductID, d.Name, i.Inventory_Qt, CAST(d.AVG_Daily_Demand AS DECIMAL(10,2)) AS AVG_Daily_Demand,
           CASE WHEN d.AVG_Daily_Demand = 0 THEN NULL
                ELSE CAST(i.Inventory_Qt / d.AVG_Daily_Demand AS DECIMAL(10,2))
           END AS Days_of_Supply
    FROM AVG_Demand d
    INNER JOIN Inventory i
        ON d.ProductID = i.ProductID
)
SELECT
    ProductID, Name, Inventory_Qt, AVG_Daily_Demand, Days_of_Supply,
    CASE WHEN Days_of_Supply <= 0 THEN 'Out of The Stock risk'
         WHEN Days_of_Supply <= 7 THEN 'High Stockout risk'
         WHEN Days_of_Supply <= 30 THEN 'Stock within limits'
         WHEN Days_of_Supply <= 90 THEN 'Overstock risk'
         WHEN Days_of_Supply > 90 THEN 'DeadStock'
    END AS DoS_Category
FROM DaysOfSupply;


-- Task 1.6 — Inventory Aging
-- Business purpose: Estimate how long inventory has been sitting in stock using the last modified date of the inventory record.
-- How this helps: Highlights potentially obsolete / slow-moving items, supporting write-off decisions, promotions, and inventory reduction actions.
-- Assumption: Uses Production.ProductInventory.ModifiedDate as a proxy for stock age because AdventureWorks does not provide receipt-date / lot-level inventory history.

SELECT
    i.ProductID, p.Name, CAST(i.ModifiedDate AS DATE) AS ModifiedDate,
    DATEDIFF(DAY, i.ModifiedDate, CAST(GETDATE() AS DATE)) AS Days_in_stock
FROM Production.ProductInventory i
INNER JOIN Production.Product p
    ON i.ProductID = p.ProductID;


-- Task 1.7 — ABC Classification (by inventory value)
-- Business purpose: Prioritize SKUs based on their contribution to total inventory value (A/B/C segmentation).
-- How this helps: Focuses control on high-value SKUs (A-class) to improve cycle counting, replenishment priority, and working capital efficiency.
-- Assumption: Inventory value is based on StandardCost * on-hand quantity (current snapshot), since AdventureWorks does not provide receipt-level valuation history.

WITH Product_Inventory_Value AS (
    SELECT
        i.ProductID, p.Name,
        SUM(i.Quantity * p.StandardCost) AS Inventory_Value,
        SUM(SUM(i.Quantity * p.StandardCost)) OVER () AS Total_Inventory_Value
    FROM Production.ProductInventory i
    INNER JOIN Production.Product p
        ON i.ProductID = p.ProductID
    GROUP BY i.ProductID, p.Name
),
Value_Share AS (
    SELECT
        ProductID, Name,
        (CAST(Inventory_Value AS DECIMAL(18,6)) / CAST(Total_Inventory_Value AS DECIMAL(18,6)) * 100) AS Value_Share_Pct
    FROM Product_Inventory_Value
    WHERE Inventory_Value > 0
),
Cumulative_Share AS (
    SELECT
        ProductID, Name, Value_Share_Pct,
        SUM(Value_Share_Pct) OVER (ORDER BY Value_Share_Pct DESC) AS Cumulative_Share_Pct
    FROM Value_Share
)
SELECT
    ProductID, Name, CAST(Cumulative_Share_Pct AS DECIMAL(10,2)) AS Cum_Share_Pct,
    CASE WHEN Cumulative_Share_Pct <= 80 THEN 'A'
         WHEN Cumulative_Share_Pct <= 95 THEN 'B'
         WHEN Cumulative_Share_Pct <= 100 THEN 'C'
    END AS ABC_Class
FROM Cumulative_Share
ORDER BY Cum_Share_Pct;

-- Task 1.8 — Safety Stock
-- Business purpose: Calculate safety stock based on demand variability and supplier lead time.
-- How this helps: Protects service level against demand and delivery uncertainty, reducing the risk of stockouts.
-- Assumption: Uses last 30 days of sales to estimate demand variability and average lead time from purchase orders,
--             because AdventureWorks does not provide explicit safety stock or service-level targets.
-- Assumption: Z-score fixed at 1.65 (~95% service level).

WITH Range_Date AS (
    SELECT DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date, MAX(OrderDate) AS End_Date
    FROM Sales.SalesOrderHeader
),
Daily_Sales AS (
    SELECT CAST(sh.OrderDate AS DATE) AS OrderDate, sd.ProductID, SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date) AND (SELECT End_Date FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS DATE), sd.ProductID
),
Demand_Stats AS (
    SELECT
        ProductID,
        AVG(CAST(Daily_Order_Qty AS FLOAT)) AS Avg_Daily_Demand,
        STDEVP(CAST(Daily_Order_Qty AS FLOAT)) AS Demand_Std_Dev
    FROM Daily_Sales
    GROUP BY ProductID
),
Lead_Time AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS FLOAT)) AS Avg_Lead_Time
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
)
SELECT
    ds.ProductID, p.Name, ds.Avg_Daily_Demand, ROUND(ds.Demand_Std_Dev, 2) AS Demand_Std_Dev,
    lt.Avg_Lead_Time,
    ROUND(1.65 * ds.Demand_Std_Dev * SQRT(lt.Avg_Lead_Time), 2) AS Safety_Stock
FROM Demand_Stats ds
INNER JOIN Lead_Time lt
    ON ds.ProductID = lt.ProductID
INNER JOIN Production.Product p
    ON ds.ProductID = p.ProductID
WHERE ds.Demand_Std_Dev IS NOT NULL
  AND lt.Avg_Lead_Time IS NOT NULL;

-- Task 1.9 — Reorder Point (ROP)
-- Business purpose: Determine the inventory level at which a replenishment order should be triggered to avoid shortages during lead time.
-- How this helps: Helps planners reorder at the right moment, balancing stockout risk vs excess inventory and improving service level.
-- Assumption: Average daily demand is estimated from last 30 days of sales and lead time from purchase orders in AdventureWorks.
-- Assumption: Safety stock uses Z = 1.65 (~95% service level).

WITH Range_Date AS (
    SELECT DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date, MAX(OrderDate) AS End_Date
    FROM Sales.SalesOrderHeader
),
Daily_Sales AS (
    SELECT CAST(sh.OrderDate AS DATE) AS OrderDate, sd.ProductID, SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date) AND (SELECT End_Date FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS DATE), sd.ProductID
),
Demand_Stats AS (
    SELECT
        ProductID,
        AVG(CAST(Daily_Order_Qty AS FLOAT)) AS Avg_Daily_Demand,
        STDEVP(CAST(Daily_Order_Qty AS FLOAT)) AS Demand_Std_Dev
    FROM Daily_Sales
    GROUP BY ProductID
),
Lead_Time AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS FLOAT)) AS Avg_Lead_Time
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
),
Safety_Stock AS (
    SELECT
        ds.ProductID, ds.Avg_Daily_Demand, ds.Demand_Std_Dev, lt.Avg_Lead_Time,
        (1.65 * ds.Demand_Std_Dev * SQRT(lt.Avg_Lead_Time)) AS Safety_Stock
    FROM Demand_Stats ds
    INNER JOIN Lead_Time lt
        ON ds.ProductID = lt.ProductID
)
SELECT
    ss.ProductID, p.Name, ss.Avg_Daily_Demand, ROUND(ss.Demand_Std_Dev, 2) AS Demand_Std_Dev,
    ss.Avg_Lead_Time, ROUND(ss.Safety_Stock, 2) AS Safety_Stock,
    ROUND((ss.Avg_Daily_Demand * ss.Avg_Lead_Time) + ss.Safety_Stock, 2) AS Reorder_Point
FROM Safety_Stock ss
INNER JOIN Production.Product p
    ON ss.ProductID = p.ProductID
WHERE ss.Avg_Lead_Time IS NOT NULL
  AND ss.Avg_Daily_Demand IS NOT NULL;

-- Task 1.10 — MOQ (Minimum Order Quantity)
-- Business purpose: Estimate a practical minimum order quantity needed to cover demand during lead time.
-- How this helps: Supports purchasing decisions by suggesting an order size that avoids frequent small orders and reduces stockout risk during replenishment.
-- Assumption: True supplier MOQ is not available in AdventureWorks; MOQ is approximated as average weekly demand * average lead time (in weeks).
-- Assumption: Weekly demand is computed from the last 30 days of sales (ISO week aggregation).

WITH Range_Date AS (
    SELECT DATEADD(DAY, -30, MAX(OrderDate)) AS Start_Date, MAX(OrderDate) AS End_Date
    FROM Sales.SalesOrderHeader
),
Daily_Sales AS (
    SELECT CAST(sh.OrderDate AS DATE) AS OrderDate, sd.ProductID, SUM(sd.OrderQty) AS Daily_Order_Qty
    FROM Sales.SalesOrderDetail sd
    INNER JOIN Sales.SalesOrderHeader sh
        ON sd.SalesOrderID = sh.SalesOrderID
    WHERE sh.OrderDate BETWEEN (SELECT Start_Date FROM Range_Date) AND (SELECT End_Date FROM Range_Date)
    GROUP BY CAST(sh.OrderDate AS DATE), sd.ProductID
),
Weekly_Sales AS (
    SELECT DATEPART(YEAR, OrderDate) AS YR, DATEPART(ISO_WEEK, OrderDate) AS WK, ProductID,
           SUM(Daily_Order_Qty) AS Weekly_Order_Qty
    FROM Daily_Sales
    GROUP BY DATEPART(YEAR, OrderDate), DATEPART(ISO_WEEK, OrderDate), ProductID
),
Avg_Weekly_Demand AS (
    SELECT ProductID, AVG(CAST(Weekly_Order_Qty AS FLOAT)) AS Avg_Weekly_Demand
    FROM Weekly_Sales
    GROUP BY ProductID
),
Lead_Time_Weeks AS (
    SELECT
        pd.ProductID,
        AVG(CAST(DATEDIFF(DAY, ph.OrderDate, ph.ShipDate) AS FLOAT)) / 7.0 AS Avg_Lead_Time_Weeks
    FROM Purchasing.PurchaseOrderDetail pd
    INNER JOIN Purchasing.PurchaseOrderHeader ph
        ON pd.PurchaseOrderID = ph.PurchaseOrderID
    WHERE ph.ShipDate IS NOT NULL
    GROUP BY pd.ProductID
)
SELECT
    d.ProductID, p.Name, lt.Avg_Lead_Time_Weeks, d.Avg_Weekly_Demand,
    CEILING(d.Avg_Weekly_Demand * lt.Avg_Lead_Time_Weeks) AS MOQ
FROM Avg_Weekly_Demand d
INNER JOIN Lead_Time_Weeks lt
    ON d.ProductID = lt.ProductID
INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID;




