
-- Step 1: Clean and validate source tables
-- Remove invalid or null values

-- Clean Customer Table
DELETE FROM DimCustomer
WHERE Customer IS NULL OR CustomerID IS NULL;

-- Clean Product Table
DELETE FROM DimProduct
WHERE Product IS NULL OR License IS NULL;

-- Clean Date Table
DELETE FROM DimDate
WHERE Date IS NULL;

-- Clean Raw Sales Table
DELETE FROM RawSales
WHERE Sales IS NULL OR Profit IS NULL OR OrderDate IS NULL;

-- Step 2: Create Fact Table with enriched metadata
SELECT
    f.OrderID,
    f.CustomerID,
    c.Customer,
    c.Segment,
    c.Industry,
    c.Country,
    c.Region,
    c.Subregion,
    f.Product,
    p.License,
    f.Discount,
    f.Profit,
    f.Sales,
    d.Date,
    d.Month,
    d.Quarter,
    d.Year
INTO FactSalesData
FROM RawSales f
JOIN DimCustomer c ON f.CustomerID = c.CustomerID
JOIN DimProduct p ON f.Product = p.Product
JOIN DimDate d ON f.OrderDate = d.Date
WHERE f.Sales > 0 AND f.Profit IS NOT NULL;

-- Step 3: Handle unknown or uncategorized data
UPDATE FactSalesData
SET Industry = 'Unknown'
WHERE Industry IS NULL;

UPDATE FactSalesData
SET Segment = 'Other'
WHERE Segment IS NULL;

-- Step 4: Customer-level metrics (summary table)
SELECT
    CustomerID,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    AVG(Discount) AS AvgDiscount,
    SUM(Profit) * 1.0 / NULLIF(SUM(Sales), 0) AS ProfitMargin
INTO CustomerSummary
FROM FactSalesData
GROUP BY CustomerID;

-- Step 5: Create a reporting view for Power BI
CREATE VIEW v_SalesOverview AS
SELECT
    Country,
    Segment,
    License,
    Year,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    AVG(Discount) AS AvgDiscount
FROM FactSalesData
GROUP BY Country, Segment, License, Year;
