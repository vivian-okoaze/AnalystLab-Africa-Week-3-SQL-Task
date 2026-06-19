--1. DATABASE SETUP

--Preview all the Tables
SELECT * FROM Album;
SELECT * FROM Artist;
SELECT * FROM Customer;
SELECT * FROM Employee;
SELECT * FROM Genre;
SELECT * FROM Invoice;
SELECT * FROM InvoiceLine;
SELECT * FROM MediaType;
SELECT * FROM Playlist;
SELECT * FROM PlaylistTrack
SELECT * FROM Track;

--Check the Number of Rows
SELECT COUNT (*) AS TotalRows FROM ALBUM;
SELECT COUNT (*) AS TotalRows FROM Artist;
SELECT COUNT (*) AS TotalRows FROM Customer;
SELECT COUNT (*) AS TotalRows FROM Employee;
SELECT COUNT (*) AS TotalRows FROM Genre;
SELECT COUNT (*) AS TotalRows FROM Invoice;
SELECT COUNT (*) AS TotalRows FROM InvoiceLine;
SELECT COUNT (*) AS TotalRows FROM MediaType;
SELECT COUNT (*) AS TotalRows FROM Playlist;
SELECT COUNT (*) AS TotalRows FROM PlaylistTrack;
SELECT COUNT (*) AS TotalRows FROM Track;

--Identification of Primary Keys (one per table)
SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    i.name AS ConstraintName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.is_primary_key = 1
ORDER BY t.name;

--2. CORE SQL QUERIES

--Select/ Where /Order by
SELECT * FROM Customer
WHERE Country = 'Brazil';

--Null Values in Invoice & Customer Tables
SELECT Customerid, BillingAddress, BillingState 
FROM Invoice
WHERE BillingState IS NULL;

SELECT CustomerId, Company, State, Fax
FROM Customer
WHERE Company IS NULL AND Fax IS NULL;

--Longest Track (Top 10)
SELECT TOP 10 Name, Milliseconds
FROM Track
ORDER BY Milliseconds DESC;

--Group by/ Having/ Data Aggregation

--Total Customers
SELECT COUNT (CustomerId) AS Total_Customers
FROM Customer;

--Total Revenue
SELECT SUM(Total) AS Total_Revenue
FROM Invoice;

--Total Track
SELECT COUNT (*) AS Total_Track
FROM Track;

--Genre with more than 100 trracks & Average Track Length
SELECT
    g.Name AS Genre,
    COUNT(*) AS TrackCount,
    ROUND(AVG(CAST(t.Milliseconds AS FLOAT)) / 1000.0, 1) AS AvgSeconds
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name
HAVING COUNT(*) > 100
ORDER BY TrackCount DESC;

--3. ADVANCED SQL CONCEPT
--Join /Inner Join

SELECT FirstName, LastName, Total
FROM Customer 
INNER JOIN Invoice
ON Customer.CustomerId = Invoice.CustomerId;

--Top 10 Artist by Revenue
SELECT TOP 10
    ar.Name AS Artist,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Revenue
FROM InvoiceLine il
INNER JOIN Track  t  ON il.TrackId = t.TrackId
INNER JOIN Album  al ON t.AlbumId  = al.AlbumId
INNER JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY ar.Name
ORDER BY Revenue DESC;

--Left Join
SELECT FirstName, LastName, Address, Country
FROM Customer 
LEFT JOIN Invoice  
ON Customer.CustomerId = Invoice.CustomerId;

--Right Join
SELECT FirstName, LastName, Country, Fax
FROM Invoice 
RIGHT JOIN Customer 
ON Invoice.CustomerId = Customer.CustomerId;

--Subquery

--Customer Whose Total Spend is Above the Average Customer Spend
SELECT
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS Customer,
    ROUND(SUM(i.Total), 2) AS TotalSpend
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName
HAVING SUM(i.Total) > (
    SELECT AVG(CustomerTotal)
    FROM (
        SELECT SUM(Total) AS CustomerTotal
        FROM Invoice
        GROUP BY CustomerId
    ) AS PerCustomer
)
ORDER BY TotalSpend DESC;

--WINDOW FUNCTION: RANK 

--Top 5 Customers by Total Spend
SELECT CustomerId, Customer, TotalSpend, SpendRank
FROM (
    SELECT
        c.CustomerId,
        c.FirstName + ' ' + c.LastName AS Customer,
        ROUND(SUM(i.Total), 2) AS TotalSpend,
        RANK() OVER (ORDER BY SUM(i.Total) DESC) AS SpendRank
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName
) AS Ranked
WHERE SpendRank <= 5;

--WINDOW FUNCTION: ROW NUMBER, PARTTITION BY
--Monthly Revenue with a Running Total
SELECT
    Yr, Mo, MonthlyRevenue,
    ROUND(SUM(MonthlyRevenue) OVER (ORDER BY Yr, Mo), 2) AS RunningTotal
FROM (
    SELECT
        YEAR(InvoiceDate)  AS Yr,
        MONTH(InvoiceDate) AS Mo,
        ROUND(SUM(Total), 2) AS MonthlyRevenue
    FROM Invoice
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
) AS Monthly
ORDER BY Yr, Mo;

--WINDOW FUNCTION: RANK, PARTITION BY

--Best Selling Track per Genre
SELECT Genre, TrackName, Revenue, Rnk
FROM (
    SELECT
        g.Name AS Genre,
        t.Name AS TrackName,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Revenue,
        ROW_NUMBER() OVER (PARTITION BY g.Name ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS Rnk
    FROM InvoiceLine il
    JOIN Track t ON il.TrackId = t.TrackId
    JOIN Genre g ON t.GenreId = g.GenreId
    GROUP BY g.Name, t.Name
) AS RankedTracks
WHERE Rnk = 1
ORDER BY Revenue DESC;

--4. BUSINESS PROBLEM SOLVING

--Top performing products: Best Selling Tracks by Revenue
SELECT TOP 10
    t.Name AS Track,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Revenue,
    SUM(il.Quantity) AS UnitsSold
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
GROUP BY t.Name
ORDER BY Revenue DESC;

--Revenue Trend Over Time (Yearly)
SELECT
    YEAR(InvoiceDate) AS Yr,
    ROUND(SUM(Total), 2) AS YearlyRevenue,
    COUNT(*) AS InvoiceCount
FROM Invoice
GROUP BY YEAR(InvoiceDate)
ORDER BY Yr;

--Customer Purchasing Behavior
SELECT
    COUNT(DISTINCT CustomerId) AS TotalCustomers,
    COUNT(*)                   AS TotalInvoices,
    ROUND(AVG(Total), 2)       AS AvgInvoiceValue,
    ROUND(SUM(Total), 2)       AS TotalRevenue
FROM Invoice;

--Customer Purchasing Behavior: Repeat vs One-time Customers
SELECT
    SUM(CASE WHEN InvoiceCount = 1 THEN 1 ELSE 0 END) AS OneTimeCustomers,
    SUM(CASE WHEN InvoiceCount > 1 THEN 1 ELSE 0 END) AS RepeatCustomers
FROM (
    SELECT CustomerId, COUNT(*) AS InvoiceCount
    FROM Invoice
    GROUP BY CustomerId
) AS PerCustomer;

--Top markets: revenue and customer count by country
SELECT TOP 5
    c.Country,
    ROUND(SUM(i.Total), 2) AS Revenue,
    COUNT(DISTINCT c.CustomerId) AS Customers
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.Country
ORDER BY Revenue DESC;

--5. QUERY OPTIMIZATION
--Check this with Ctrl+L (Display Estimated ExecutionPlan) before and after running the CREATE INDEX statements below.

-- BEFORE: filters/groups on InvoiceDate with no supporting index,
-- so SQL Server has to scan the whole Invoice table
SELECT YEAR(InvoiceDate) AS Yr, ROUND(SUM(Total), 2) AS YearlyRevenue
FROM Invoice
GROUP BY YEAR(InvoiceDate)
ORDER BY Yr;

-- Add a non-clustered index on the column driving the trend queries
CREATE NONCLUSTERED INDEX IX_Invoice_InvoiceDate
ON Invoice (InvoiceDate)
INCLUDE (Total, CustomerId);

-- AFTER: same query, same execution-plan check (Ctrl+L) -- the new
-- index lets the optimizer narrow rows down faster, and the INCLUDE
-- columns mean SUM(Total) can be satisfied without a separate lookup
-- back to the table (a "covering index")
SELECT YEAR(InvoiceDate) AS Yr, ROUND(SUM(Total), 2) AS YearlyRevenue
FROM Invoice
GROUP BY YEAR(InvoiceDate)
ORDER BY Yr;

