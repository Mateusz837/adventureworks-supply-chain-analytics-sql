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


