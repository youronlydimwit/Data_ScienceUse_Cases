-- Customer Analysis
USE LUXTOYS_DB

--1 What is the distribution of customers based on their regions and levels?
SELECT
[Region] = c.uRegion,
[Level] = c.uLevel,
[Count] = COUNT(DISTINCT c.cusID)
FROM Customers c
GROUP BY c.uLevel, c.uRegion

--2 What is the distribution of customers that haven't filled their address info based on their Regions?
SELECT
[Region] = c.uRegion,
[Count] = FORMAT(COUNT(c.uAddress),'N0')
FROM Customers c
WHERE c.uAddress like ''
GROUP BY c.uRegion
ORDER BY COUNT(c.uAddress) DESC

--3 What is the average purchase frequency of customers, from each level, in 2024?
SELECT
[Level] = c.uLevel,
[Purchase_Freq] = FORMAT(COUNT(tr.trID), 'N0')
FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
WHERE YEAR(tr.trDate) like '2024'
GROUP BY c.uLevel
ORDER BY COUNT(tr.trID) DESC

--4 What are the top regions contributing to sales revenue in 2024?
SELECT
[Region] = c.uRegion,
[Gross_Sales] = FORMAT(SUM(tr.gross_tr), 'N0'),
[Nett_Sales] = FORMAT(SUM(tr.nett_tr), 'N0')
FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
WHERE YEAR(tr.trDate) like '2024'
GROUP BY c.uRegion
ORDER BY SUM(tr.gross_tr) DESC

--5 How does the average transaction value differ across customer levels, in 2024?
SELECT
[Level] = c.uLevel,
[Avg_Gross_Sales] = FORMAT(AVG(tr.gross_tr), 'N0'),
[Avg_Nett_Sales] = FORMAT(AVG(tr.nett_tr), 'N0')
FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
WHERE YEAR(tr.trDate) like '2024'
GROUP BY c.uLevel
ORDER BY AVG(tr.gross_tr) DESC

--6 Identify the top 10 customers based on the total gross revenue generated from their transactions in Q1 2024.
WITH RankCust AS(
	SELECT
	[Cust_Nm] = c.uName,
	[Gross] = FORMAT(SUM(tr.gross_tr), 'N0'),
	[Rank] = ROW_NUMBER() OVER (ORDER BY SUM(tr.gross_tr) DESC)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(Q, tr.trDate) = 1 AND DATEPART(YEAR, tr.trDate) = 2024
	GROUP BY c.uName
)
SELECT
[Rank], [Cust_Nm], [Gross]
FROM
RankCust
WHERE [Rank] <= 10

--7 Identify customers who made less than 3 in 2024 
-- but had at least one transaction in Q4 2023.
WITH lasix AS(
	SELECT
	[ID] = c.cusID,
	[Name] = c.uName,
	[2024] = COUNT(tr.trID)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(YEAR,tr.trDate) = 2024
	GROUP BY c.cusID, c.uName
), prsix AS(
	SELECT
	[ID] = c.cusID,
	[Name] = c.uName,
	[Q4_2023] = COUNT(tr.trID)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(YEAR,tr.trDate) = 2023 AND DATEPART(QUARTER,tr.trDate) = 4
	GROUP BY c.cusID, c.uName
)
SELECT
lasix.[ID],
lasix.[Name],
prsix.[Q4_2023],
lasix.[2024]
FROM lasix join prsix ON lasix.[ID] = prsix.[ID]
WHERE lasix.[2024] <3

--8 Identify customers who have increased their purchase frequency 
-- by more than 50% in the last quarter compared to the previous quarter.
WITH Q423 AS(
	SELECT
	[ID] = c.cusID,
	[Name] = c.uName,
	[Q4_23] = COUNT(tr.trID)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(YEAR,tr.trDate) = 2023 AND DATEPART(QUARTER,tr.trDate) = 4
	GROUP BY c.cusID, c.uName
), Q124 AS(
	SELECT
	[ID] = c.cusID,
	[Name] = c.uName,
	[Q1_24] = COUNT(tr.trID)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(YEAR,tr.trDate) = 2024 AND DATEPART(QUARTER,tr.trDate) = 1
	GROUP BY c.cusID, c.uName
)
SELECT
Q423.[ID],
Q423.[Name],
Q423.[Q4_23],
Q124.[Q1_24],
[Pct%] = FORMAT(((Q124.[Q1_24] - Q423.[Q4_23]) * 1.0 / Q423.[Q4_23]), 'P0')
FROM Q423 JOIN Q124 ON Q423.[ID] = Q124.ID
WHERE ((Q124.[Q1_24] - Q423.[Q4_23]) * 1.0 / Q423.[Q4_23]) > 0.5

--9 Analyze the total spending of high-value customers (e.g., top 10% by total spending) 
-- compared to other customers in the past year.
WITH custlist AS(
	SELECT
	[ID] = c.cusID,
	[Name] = c.uName,
	[gros] = SUM(tr.gross_tr)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE DATEPART(YEAR,tr.trDate) = 2023
	GROUP BY c.cusID, c.uName
), allcust AS(
	SELECT
	[ID], 
	[gros],
	NTILE(10) OVER (ORDER BY custlist.[gros]) AS spendRank
	From custlist
), top10 AS(
	SELECT
	[Cust_Group] = 'Top 10%',
	[Count] = COUNT(*),
	[total_gross] = SUM(allcust.[gros])
	FROM allcust 
	WHERE spendRank = 1
), oth90 AS(
	SELECT
	[Cust_Group] = 'Other 90%',
	[Count] = COUNT(*),
	[total_gross] = SUM(allcust.[gros])
	FROM allcust 
	WHERE spendRank > 1
)
SELECT
[Cust_Group],
[Count],
[Gross] = FORMAT([total_gross], 'N0'), 
[Contrib%] = FORMAT([total_gross] / (SELECT SUM([gros]) FROM custlist), 'P0')
FROM top10
UNION ALL
SELECT
[Cust_Group],
[Count],
[Gross] = FORMAT([total_gross], 'N0'), 
[Contrib%] = FORMAT([total_gross] / (SELECT SUM([gros]) FROM custlist), 'P0')
FROM oth90


--10 Identify the top 3 regions with the highest grossing value for campaigns in 2023, then compare it to its 2024 performance.
WITH TopRegions AS (
    SELECT
        c.uRegion,
        SUM(tr.gross_tr) AS total_Gross,
        ROW_NUMBER() OVER (ORDER BY SUM(tr.gross_tr) DESC) AS Rank
    FROM Customers c 
    JOIN Transact tr ON c.cusID = tr.cusID
    WHERE DATEPART(YEAR, tr.trDate) = 2023
    GROUP BY c.uRegion
)
SELECT
    t.uRegion,
    [Gross 2023] = FORMAT(t.total_Gross, 'N0'),
    [Gross 2024] = FORMAT(t24.total_Gross, 'N0')
FROM TopRegions t
LEFT JOIN (
    SELECT
        c.uRegion,
        SUM(tr.gross_tr) AS total_Gross
    FROM Customers c 
    JOIN Transact tr ON c.cusID = tr.cusID
    WHERE DATEPART(YEAR, tr.trDate) = 2024
    GROUP BY c.uRegion
) t24 ON t.uRegion = t24.uRegion
WHERE t.Rank <= 3