--1. DATABASE SETUP

CREATE DATABASE Sales_data;

--Preview After Importing Flat File
SELECT * FROM sales_data_sample;
SELECT TOP 10 * FROM Sales_data_sample;

--Check the Number of Rows
SELECT COUNT (*) AS Totalrows
FROM sales_data_sample;

--Check the Number of Columns and Column Information
SELECT COUNT (*) AS TotalColumns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales_data_sample';

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales_data_sample';

--2. CORE SQL QUERIES

--Select/ Where / Order By
SELECT PRODUCTLINE, STATUS,CUSTOMERNAME, COUNTRY
FROM sales_data_sample
WHERE COUNTRY = 'USA';

SELECT QUANTITYORDERED, STATUS,CITY, SALES
FROM sales_data_sample
WHERE PRODUCTLINE = 'PLANES'
ORDER BY SALES DESC;

SELECT TOP 10 ORDERNUMBER, PRODUCTCODE, SALES, ORDERDATE
FROM sales_data_sample
WHERE SALES > 5000
ORDER BY SALES DESC;

--Data Aggregation / Group By / Having

--Revenue By Product Line
SELECT PRODUCTLINE, 
COUNT(ORDERNUMBER) AS TOTAL_ORDERS,
ROUND(SUM(SALES),2) AS TOTAL_REVENUE,
ROUND (AVG(SALES),2) AS AVERAGE_REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY TOTAL_REVENUE;

SELECT PRODUCTLINE,
ROUND(SUM(SALES), 2) AS REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
HAVING SUM(SALES) > 100000
ORDER BY REVENUE;

--Highest Sale
SELECT
MAX(SALES) AS HIGHEST_SALE
FROM sales_data_sample;

--Lowest Sale
SELECT
MIN (SALES) AS HIGHEST_SALE
FROM sales_data_sample;

--3.ADVANCED SQL CONCEPT

--Subquery: Customer Spending

SELECT CustomerName,
ROUND(SUM(Sales), 2) AS TotalSpend
FROM sales_data_sample
GROUP BY CustomerName
HAVING SUM(Sales) > (
SELECT AVG(CustomerTotal)
FROM (SELECT SUM(Sales) AS CustomerTotal
        FROM sales_data_sample
        GROUP BY ORDERNUMBER) AS PerCustomer)
ORDER BY TotalSpend DESC;

--WINDOW FUNCTION:RANK, PARTITION BY
--Top 2 Product Line Per Year

SELECT YEAR_ID, PRODUCTLINE, YearlySales, Rnk
FROM (
    SELECT
        YEAR_ID,
        PRODUCTLINE,
        ROUND(SUM(Sales), 2) AS YearlySales,
        RANK() OVER (PARTITION BY YEAR_ID ORDER BY SUM(Sales) DESC) AS Rnk
    FROM sales_data_sample
    GROUP BY YEAR_ID, PRODUCTLINE
) AS Ranked
WHERE Rnk <= 2
ORDER BY YEAR_ID, Rnk;

--Monthly Revenue Trend
SELECT Year_id,Month_Id, MonthlyRevenue,
    ROUND(SUM(MonthlyRevenue) OVER (ORDER BY Year_Id, Month_Id), 2) AS RunningTotal
FROM (
    SELECT Year_Id, Month_Id, ROUND(SUM(Sales), 2) AS MonthlyRevenue
    FROM sales_data_sample
    GROUP BY Year_Id, Month_Id
) AS Monthly
ORDER BY Year_Id, Month_Id;

--WINDOW FUNCTION: ROW NUMBER

--Each Customer's Single Largest Order
SELECT CustomerName, OrderNumber, Sales, Rnk
FROM (
    SELECT CustomerName,OrderNumber,Sales,
        ROW_NUMBER() OVER (PARTITION BY Ordernumber ORDER BY Sales DESC) AS Rnk
    FROM sales_data_sample
) AS RankedOrders
WHERE Rnk = 1
ORDER BY Sales DESC;

--4. BUSINESS PROBLEM SOLVING

--Top Performing Product
SELECT ProductLine,
    SUM(QuantityOrdered) AS UnitsSold,
    ROUND(SUM(Sales), 2) AS Revenue
FROM sales_data_sample
GROUP BY ProductLine
ORDER BY Revenue DESC;

--Revenue Trend Over Time (By Year & Quarter)
SELECT Year_Id, Qtr_Id,
    ROUND(SUM(Sales), 2) AS QuarterlyRevenue
FROM sales_data_sample
GROUP BY Year_Id, Qtr_Id
ORDER BY Year_Id, Qtr_Id;

--Customer Purchasing Behaviour

SELECT
    COUNT(DISTINCT ORDERNUMBER) AS TotalCustomers,
    SUM(CASE WHEN OrderCount = 1 THEN 1 ELSE 0 END) AS OneTimeCustomers,
    SUM(CASE WHEN OrderCount > 1 THEN 1 ELSE 0 END) AS RepeatCustomers
FROM (
    SELECT ORDERNUMBER, COUNT(DISTINCT OrderNumber) AS OrderCount
    FROM sales_data_sample
    GROUP BY ORDERNUMBER
) AS PerCustomer;


SELECT DealSize,
    COUNT(*) AS OrderLines,
    ROUND(AVG(Sales), 2) AS AvgLineValue
FROM sales_data_sample
GROUP BY DealSize
ORDER BY AvgLineValue DESC;

--Top Markets: Revenue & Customer by Country

SELECT TOP 5 Country,
    ROUND(SUM(Sales), 2) AS Revenue,
    COUNT(DISTINCT Ordernumber) AS Customers
FROM sales_data_sample
GROUP BY Country
ORDER BY Revenue DESC;

--5. Query Optimization

--Check this with Ctrl+L (Display Estimated ExecutionPlan) before and after running the CREATE INDEX statements below.

-- BEFORE: run with Ctrl+L and note the Clustered Index Scan on Orders

SELECT PRODUCTLINE, SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY TotalSales DESC;

-- One per Column that gets Grouped/Filtered on Repeatedly Queries
CREATE NONCLUSTERED INDEX IX_Sales_ProductLine
    ON sales_data_sample (PRODUCTLINE) INCLUDE (SALES, QUANTITYORDERED);

CREATE NONCLUSTERED INDEX IX_Sales_CustomerName
    ON sales_data_sample (CUSTOMERNAME) INCLUDE (SALES);

CREATE NONCLUSTERED INDEX IX_Sales_Country
    ON Sales_data_sample (COUNTRY) INCLUDE (SALES);

CREATE NONCLUSTERED INDEX IX_Sales_YearMonth
    ON Sales_data_sample (YEAR_ID, MONTH_ID) INCLUDE (SALES);

    -- AFTER: same query, re-check the plan with Ctrl+L -- the join now
-- uses an Index Seek/Scan on Orders instead of scanning every row

SELECT PRODUCTLINE, SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY TotalSales DESC;

SELECT COUNTRY, SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY COUNTRY
ORDER BY TotalSales DESC;