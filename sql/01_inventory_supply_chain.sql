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



