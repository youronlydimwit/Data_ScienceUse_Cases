-- Transaction Analysis
USE LUXTOYS_DB

--1 What are the monthly sales trends in terms of gross and nett transactions, in 2024?
SELECT
[Month] = MONTH(tr.trDate),
[Gross_Sales] = FORMAT(SUM(tr.gross_tr), 'N0'),
[Nett_Sales] = FORMAT(SUM(tr.nett_tr), 'N0')
FROM Transact tr
WHERE YEAR(tr.trDate) like '2024'
GROUP BY MONTH(tr.trDate)

--2 Which payment types are most commonly used in transactions?
SELECT
[Pay_Type] = tr.payType,
[Count] = COUNT(tr.payType)
FROM Transact tr
GROUP BY tr.payType
ORDER BY COUNT(tr.payType) DESC

--3 Which days of the week have the highest transaction volumes and Nett revenue?
SELECT
[Day_of_Week] = DATENAME(WEEKDAY, tr.trDate),
[Volume] = FORMAT(COUNT(tr.trID), 'N0'),
[Nett_Revenue] = FORMAT(SUM(tr.nett_tr), 'N0')
FROM Transact tr JOIN transactDetail td ON tr.trID = td.trID
GROUP BY DATENAME(WEEKDAY, tr.trDate), DATEPART(WEEKDAY, tr.trDate)
ORDER BY DATEPART(WEEKDAY, tr.trDate) ASC

--4 How many transactions involve promotional campaigns?
SELECT
[Is_Campaign] = td.is_campaign,
[Count] = COUNT(tr.trID)
FROM Transact tr JOIN transactDetail td ON tr.trID = td.trID
GROUP BY td.is_campaign

--5 What is the average transaction size by store?
SELECT
[Store] = s.storeName,
[total_sold] = SUM(td.qty),
[avg_sold] = AVG(td.qty)
FROM Store s JOIN Transact tr ON s.storeID = tr.storeID JOIN transactDetail td ON tr.trID = td.trID 
GROUP BY s.storeName

--6 Compare Q1 performance of 2023 and 2024
WITH Q123 AS (
	SELECT
		[Period] = 'Q1 2023',
		[Gross] = FORMAT(SUM(tr.gross_tr), 'N0'),
		[Qty] = FORMAT(SUM(td.qty), 'N0'),
		[Nett] = FORMAT(SUM(tr.nett_tr), 'N0')
	FROM Transact tr 
	JOIN transactDetail td ON tr.trID = td.trID
	WHERE DATEPART(YEAR, tr.trDate) = 2023
),
Q124 AS (
	SELECT
		[Period] = 'Q1 2024',
		[Gross] = FORMAT(SUM(tr.gross_tr), 'N0'),
		[Qty] = FORMAT(SUM(td.qty), 'N0'),
		[Nett] = FORMAT(SUM(tr.nett_tr), 'N0')
	FROM Transact tr 
	JOIN transactDetail td ON tr.trID = td.trID
	WHERE DATEPART(YEAR, tr.trDate) = 2024
)
SELECT 
	[Period],
	[Qty],
	[Gross],
	[Nett]
FROM Q123
UNION ALL
SELECT 
	[Period],
	[Qty],
	[Gross],
	[Nett]
FROM Q124

--7 Determine the frequency of transactions per customer 
-- in May 2024 and identify customers who have 
-- an unusually high number of transactions compared to the average in that month.
WITH unhigh AS(
	SELECT
	[cuID] = c.cusID,
	[cuName] = c.uName,
	[count_tr] = COUNT(DISTINCT tr.trID),
	[Rnk] = ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT tr.trID) DESC)
	FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
	WHERE YEAR(tr.trDate) = 2024 AND DATEPART(MONTH,tr.trDate) = 5
	GROUP BY c.cusID, c.uName
), meanTr AS(
	SELECT
	[average_tr] = AVG(count_tr)
	FROM (
		SELECT
		[cuID] = c.cusID,
		[count_tr] = COUNT(DISTINCT tr.trID)
		FROM Customers c JOIN Transact tr ON c.cusID = tr.cusID
		WHERE YEAR(tr.trDate) = 2024 AND DATEPART(MONTH,tr.trDate) = 5
		GROUP BY c.cusID
	) AS trCtz
)
SELECT
unhigh.[cuID], 
unhigh.[cuName], 
unhigh.[count_tr], 
meanTr.average_tr, 
[Difference] = meanTr.[average_tr] - unhigh.[count_tr] 
FROM unhigh CROSS JOIN meanTr 
WHERE [Rnk] <=5


--8 Calculate the percentage change in monthly transaction counts in Jan-24 for each store compared to Dec-23
WITH on24 AS(
	SELECT
	[store] = s.storeName,
	[Jan-24] = COUNT(DISTINCT tr.trID)
	FROM Store s JOIN Transact tr ON s.storeID = tr.storeID
	WHERE YEAR(tr.trDate) = 2024 AND DATEPART(MONTH, tr.trDate) = 1
	GROUP BY s.storeName
), on23 AS(
	SELECT
	[store] = s.storeName,
	[Dec-23] = COUNT(DISTINCT tr.trID)
	FROM Store s JOIN Transact tr ON s.storeID = tr.storeID
	WHERE YEAR(tr.trDate) = 2023 AND DATEPART(MONTH, tr.trDate) = 12
	GROUP BY s.storeName
)
SELECT
on24.[store],
on24.[Jan-24],
on23.[Dec-23],
[Change] = FORMAT(((on24.[Jan-24] - on23.[Dec-23]) * 1.0 / on23.[Dec-23]), 'P0')
FROM 
on23 JOIN on24 ON on23.[store] = on24.[store]

--9 Find the top-performing products 
--based on the revenue generated from transactions in the Q1 2024, 
--and compare their performance to Q4 2023.
WITH RankQ124 AS(
	SELECT
	[Period] = 'Q1 2024',
	[Prod_Nm] = p.prodName,
	[Nett_Revenue] = SUM(td.nett_detail),
	[Rnk] = ROW_NUMBER() OVER (ORDER BY SUM(td.nett_detail) DESC)
	FROM Product p JOIN transactDetail td ON p.prodID = td.prodID JOIN Transact tr ON tr.trID = td.trID
	WHERE DATEPART(QUARTER,tr.trDate) = 1 AND DATEPART(YEAR,tr.trDate) = 2024
	GROUP BY p.prodName
), RankQ423 AS(
	SELECT
	[Period] = 'Q4 2023',
	[Prod_Nm] = p.prodName,
	[Nett_Revenue] = SUM(td.nett_detail),
	[Rnk] = ROW_NUMBER() OVER (ORDER BY SUM(td.nett_detail) DESC)
	FROM Product p JOIN transactDetail td ON p.prodID = td.prodID JOIN Transact tr ON tr.trID = td.trID
	WHERE DATEPART(QUARTER,tr.trDate) = 4 AND DATEPART(YEAR,tr.trDate) = 2023
	GROUP BY p.prodName
)
SELECT
[Period], [Prod_Nm], FORMAT([Nett_Revenue],'N0') AS Nett, [Rnk]
FROM RankQ124
WHERE Rnk <6
UNION ALL
SELECT
[Period], [Prod_Nm], FORMAT([Nett_Revenue],'N0') AS Nett, [Rnk]
FROM RankQ423
WHERE Rnk <6

-- 10 Analyze the impact of promotional campaigns on transaction volumes and revenue, 
-- comparing Q1 2023 and Q1 2024 with and without campaigns.
WITH YCamp AS(
	SELECT
	[Year] = YEAR(tr.trDate),
	[Campaign_Type] = td.is_campaign,
	[tr_Volume] = COUNT(DISTINCT tr.trID),
	[revenue] = SUM(tr.nett_tr)
	FROM Transact tr JOIN transactDetail td ON tr.trID = td.trID
	WHERE YEAR(tr.trDate) = 2023
	GROUP BY YEAR(tr.trDate), td.is_campaign
), NCamp AS(
	SELECT
	[Year] = YEAR(tr.trDate),
	[Campaign_Type] = td.is_campaign,
	[tr_Volume] = COUNT(DISTINCT tr.trID),
	[revenue] = SUM(tr.nett_tr)
	FROM Transact tr JOIN transactDetail td ON tr.trID = td.trID
	WHERE YEAR(tr.trDate) = 2024
	GROUP BY YEAR(tr.trDate), td.is_campaign
)
SELECT
[Year], [Campaign_Type], [tr_Volume], FORMAT([revenue],'N0') AS Revenue FROM YCamp 
UNION ALL
SELECT
[Year], [Campaign_Type], [tr_Volume], FORMAT([revenue],'N0') AS Revenue FROM NCamp