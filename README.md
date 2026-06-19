# SQL & Data Querying 

![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![SSMS](https://img.shields.io/badge/Tool-SSMS-0078D4?logo=microsoft&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

Week 3 of the AnalystLab Africa Data Analytics Internship Program, focused on building practical SQL skills for data querying and business analysis using two real-world datasets: the Chinook music store database and a sample sales transactions dataset.


## Table of Contents

- [Overview](#overview)
- [Datasets](#datasets)
- [Tools](#tools)
- [Repository Structure](#repository-structure)
- [Database Setup](#database-setup)
- [Schema Relationships](#schema-relationships)
- [Query Breakdown](#query-breakdown)
- [Query Optimization](#query-optimization)
- [Key Insights](#key-insights)
- [Challenges and Decisions](#challenges-and-decisions)
- [How to Run](#how-to-run)
- [Skills Demonstrated](#skills-demonstrated)
- [Author](#author)

## Overview

**Objective:** develop strong SQL querying skills by extracting and transforming structured data, writing efficient queries, and solving business-driven analytical questions across two datasets of different structure and scale.

The two datasets were deliberately chosen by the program to represent opposite ends of the schema spectrum:

- **Chinook** arrives already normalized — eleven related tables with defined primary and foreign keys — so the work is about navigating an existing relational structure correctly.
- **Sales Data** arrives as a single denormalized CSV with no keys or constraints — every row repeats the full customer address and product details — so the work is about recognizing what a normalized version *would* look like and deciding whether to model it relationally or query the flat structure directly.

Both paths are covered in this repository, including the reasoning behind that decision (see [Challenges and Decisions](#challenges-and-decisions)).

## Datasets

| Dataset | Description | Source |
|---|---|---|
| **Chinook** | A normalized music store database — artists, albums, tracks, genres, customers, employees, and invoices | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) |
| **Sales Data** | A flat sales transactions export — orders, products, customers, and order details across 2003–2005 | [Kaggle: kyanyoga/sample-sales-data](https://www.kaggle.com/datasets/kyanyoga/sample-sales-data) |


## Tools

- **Microsoft SQL Server** — database engine
- **SQL Server Management Studio (SSMS)** — query execution, execution plan analysis, database diagramming
- **T-SQL** — query language (note: syntax such as `TOP n`, `+` for string concatenation, and `YEAR()`/`MONTH()` for date parts is SQL Server–specific and differs from MySQL/PostgreSQL equivalents like `LIMIT`, `CONCAT()`, and `EXTRACT()`)

## Repository Structure

```
├── Chinook_Queries.sql            # Task 1: All Chinook database queries (5 sections)
├── Sales_Queries.sql              # Task 2: All sales dataset queries (5 sections)
└── README.md                      # This file
```

## Database Setup

### Chinook
Restored directly from the official `Chinook_SqlServer.sql` script, which creates the database, all eleven tables, and loads the full dataset in a single execution — no manual schema design required.

### Sales Data
Imported via the SSMS **Import Flat File** wizard, which auto-detects column types from the CSV header and creates a single table matching the original 25-column structure (order number, product code, customer name, address fields, sales figures, and date fields all in one row per order line). Because the wizard typically creates this as a **heap** (no clustered index, no defined key), index strategy for this dataset is handled differently than for Chinook — see [Query Optimization](#query-optimization).

## Schema Relationships

### Chinook — entity relationship summary

Chinook is fully normalized. The two main chains worth understanding:

```
Artist (1) ───< Album (1) ───< Track ───< InvoiceLine >─── (1) Invoice >─── (1) Customer
                                  │                                              │
                                  └──< PlaylistTrack >── Playlist                └── SupportRepId → Employee
                                  │                                                          │
                                  ├── GenreId → Genre                                ReportsTo → Employee (self-referencing)
                                  └── MediaTypeId → MediaType
```
<img width="575" height="425" alt="Screenshot 2026-06-18 210144" src="https://github.com/user-attachments/assets/dada48f9-75f8-4898-a75b-9dba624fad4c" />


Key things to note about this structure:
- **Revenue is not stored anywhere as a single number.** It only exists as `InvoiceLine.UnitPrice × InvoiceLine.Quantity`, so every revenue question requires a join through `InvoiceLine`.
- **Employee is self-referencing** — `Employee.ReportsTo` points back to another row in the same table, modeling a reporting hierarchy.
- Every foreign key in Chinook's official build script already has a supporting index, *except* `Invoice.InvoiceDate` — relevant for the optimization section below.


### Sales Data 

The raw CSV has no enforced keys.

Each order line belongs to exactly one product and one customer; each product or customer can appear across many order lines. This repository includes a normalized version of this structure (Products / Customers / Orders) In practice, querying the flat imported table directly produces analytical results, since a `GROUP BY` on the flat table answers the same questions.

## Query Breakdown

Both `.sql` files follow the same five-section structure, mirroring the assignment's task breakdown:

| Section | Focus | Example queries included |
|---|---|---|
| **1. Database Setup** | Schema verification| Row counts per table, Previewing all the tables |
|**2. Core SQL Queries** | `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, aggregates | Longest tracks; genres with 100+ tracks and their average length; high-value order lines; revenue by product line |
| **3. Advanced SQL Concepts** | Joins, subqueries, window functions | 4-table `INNER JOIN` for artist revenue; `LEFT`/`RIGHT JOIN` to detect customers/products with zero activity; subquery for above-average spenders; `RANK()` for top-5 customers; `ROW_NUMBER() OVER (PARTITION BY ...)` for best-seller-per-category |
| **4. Business Problem Solving** | Answering the assignment's specific business questions | Top-performing products/artists; yearly and quarterly revenue trends with running totals; repeat vs. one-time customer split; top markets by country |
| **5. Query Optimization** | Indexing and execution plan analysis | Before/after `CREATE NONCLUSTERED INDEX` comparison using `Ctrl+L` execution plans; notes on sargable vs. non-sargable filtering |


## Query Optimization

Two different indexing problems show up across the two datasets, which is itself a useful finding:

- **Chinook** already has every foreign key indexed by its official setup script. The one gap is `Invoice.InvoiceDate`, used in every revenue-trend query but with no supporting index. A covering non-clustered index (`InvoiceDate`, including `Total` and `CustomerId`) was added and verified using SSMS's *Display Estimated Execution Plan* (`Ctrl+L`) before and after — the read operator changed from a full scan to an index seek/scan against the narrower index.
- **Sales Data**, imported as a flat heap table, has no indexes at all by default. Indexes were added on the columns repeatedly used in `GROUP BY`/`WHERE` across the query set (`PRODUCTLINE`, `CUSTOMERNAME`, `COUNTRY`, and the `YEAR_ID`/`MONTH_ID` pair), each with relevant columns in `INCLUDE` so aggregates can be satisfied directly from the index without a lookup back to the full 25-column row.

One nuance documented in the scripts: queries with no `WHERE` clause (full-table aggregations) show an **Index Scan**, not an **Index Seek**, even after indexing — this is expected, since a Seek only applies when filtering narrows the row set. The performance gain in that case comes from reading a narrow index instead of the full wide table, not from skipping rows.

## Key Insights

### Chinook
- **Iron Maiden** is the top revenue-generating artist ($138.60), ahead of U2 ($105.93) and Metallica ($90.09).
- **Rock** is the single largest genre by track count (1,297 of 3,503 tracks, over a third of the entire catalog), followed by Latin, Metal, Alternative & Punk, and Jazz.
- Every customer in the dataset has made at least one purchase — there is no inactive/never-converted customer segment.
- Revenue is geographically concentrated: the **USA, Canada, and France** together account for roughly 44% of total revenue from under a third of all customers.
- Total revenue across the dataset is $2,328.60 across 412 invoices (average invoice value: $5.65).

### Sales Data
- **Classic Cars** is the dominant product line — $3,919,615.66 in revenue (more than double the next category, Vintage Cars at $1,903,150.84) — and holds the #1 spot in every year in the dataset (2003, 2004, 2005), confirmed via a `RANK() OVER (PARTITION BY YearId ...)` window function.
- Two customer accounts, **Euro Shopping Channel** ($912,294.11) and **Mini Gifts Distributors Ltd.** ($654,858.06), together account for roughly 21% of total company revenue — a meaningful concentration risk.
- **91 of 92 customers** are repeat buyers (more than one order), indicating the business runs on recurring relationships rather than one-off transactions.
- The **USA** dominates by country ($3,627,982.83 from 35 customers), more than triple the next country (Spain, $1,215,686.92) — though Spain's figure is almost entirely explained by the single Euro Shopping Channel account.

## Challenges and Decisions

- **Flat sales data.** The sales CSV imports as one denormalized table. Queried flat to produce analytical results.
- **Date handling on import.** `ORDERDATE` in the raw CSV imports with a time component (`2/24/2003 0:00`) that needed casting to `DATE` for clean grouping by year/quarter/month.
- **Non-sargable filtering.** Early trend queries wrapped `InvoiceDate` in `YEAR()`, which works correctly but prevents efficient index seeks at scale., along with a literal date-range rewrite as the more scalable alternative.
- **RANK() vs. ROW_NUMBER().** Chosen deliberately depending on the question — `RANK()` for "top N by spend" questions where ties should share a rank (and did occur, e.g. two customers tied at $45.62), and `ROW_NUMBER()` where exactly one row per group is required (e.g. each customer's single largest order).

## How to Run

1. Restore the Chinook database in SQL Server using the official [`Chinook_SqlServer.sql`](https://github.com/lerocha/chinook-database) setup script.
2. Download `sales_data_sample.csv` from Kaggle and import it into SQL Server using the SSMS **Import Flat File** wizard.
3. Open `Chinook_Queries.sql` in SSMS, set the database context to `Chinook`, and run each section in order.
4. Open `Sales_Queries.sql` in SSMS, set the database context to your sales database, and run each section in order (adjust table/column names if your import wizard named them differently).

## Skills Demonstrated

`SQL` · `T-SQL` · `Relational Database Design` · `Joins (INNER/LEFT/RIGHT)` · `Subqueries` · `Window Functions (RANK, ROW_NUMBER, PARTITION BY)` · `Aggregate Functions` · `Query Optimization` · `Execution Plan Analysis` · `Indexing` · `Business Analytics` · `Data Normalization`

## Author

**Vivian Okoaze**

Data Analyst Intern
