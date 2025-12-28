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

