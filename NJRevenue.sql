--Simple exploration of the revenue from agencies and authorities in New Jersey from 6/2011 to today 
--Data Obtained from https://data.nj.gov/Government-Finance/YourMoney-Combined-Revenue/akr9-8jzi

--Taking a look at the entire table. 
SELECT * FROM YourMoney_Combined_Revenue

--Selecting Top 10 overall higest revenuse by agency year to date. 
Select TOP 10 
	AGENCY_AUTHORITY_NAME, 
	REVENUE_CATEGORY_DESC,
	YTD_AMT 
FROM YourMoney_Combined_Revenue 
ORDER BY YTD_AMT Desc

--Output of this queries leads to very large numbers without any commas, making it difficult to read. 
--Let's change the format of the column to make the output more readable, however still sorting by the orignial column 
--to ensure we don't influence the sorting done by ORDER BY as the column will be formatted into a string type.
Select TOP 10 
	AGENCY_AUTHORITY_NAME, 
	REVENUE_CATEGORY_DESC,
	FORMAT(YTD_AMT, N'N2') YearToDateAmount 
FROM YourMoney_Combined_Revenue 
ORDER BY YTD_AMT Desc 

--This shows statewide agency major revenue as the highest revenue earner year to date, a very broad category. 
--Lets compare the average yearly revenue per agency, ordered by agency name and year. 

SELECT 
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR as FiscalYear, 
	FORMAT(AVG(YTD_AMT), N'N2') AverageYearlyAmount 
FROM YourMoney_Combined_Revenue YMCR
GROUP BY AGENCY_AUTHORITY_NAME, ACCOUNTING_FISCAL_YEAR
ORDER BY AGENCY_AUTHORITY_NAME, FiscalYear

--Let's go further and check the difference in average revenue year over year for each agency using a CTE. 

WITH AvgRev as (
SELECT
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR FiscalYear, 
	AVG(YTD_AMT) AverageYearlyAmount, 
	LEAD(AVG(YTD_AMT)) 
		OVER (PARTITION BY AGENCY_AUTHORITY_NAME ORDER BY ACCOUNTING_FISCAL_YEAR) NextYrAvg
FROM YourMoney_Combined_Revenue
GROUP BY AGENCY_AUTHORITY_NAME, ACCOUNTING_FISCAL_YEAR)

SELECT
	AGENCY_AUTHORITY_NAME, 
	FiscalYear, 
	FORMAT(AverageYearlyAmount, N'N2') AverageYearlyAmount,
	ISNULL(FORMAT(NextYrAvg, N'N2'), 'TBD') FollowingYearAverage, 
	ISNULL(FORMAT((NextYrAvg-AverageYearlyAmount), N'N2'), 'TBD') DifferenceInRevenue
FROM AvgRev
ORDER BY AGENCY_AUTHORITY_NAME, (NextYrAvg-AverageYearlyAmount)

--Finding the month and year with highest average revenue for each department. 

WITH CTE as (
SELECT 
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR, 
	MONTH(MONTH_ENDING_DATE) as FiscalMonth,
	FORMAT(AVG(YTD_AMT), N'N2') AvgRevPerMon,
	RANK() 
		OVER (PARTITION BY AGENCY_AUTHORITY_NAME ORDER BY AVG(YTD_AMT) desc) ColRank
FROM YourMoney_Combined_Revenue
GROUP BY AGENCY_AUTHORITY_NAME, ACCOUNTING_FISCAL_YEAR, MONTH(MONTH_ENDING_DATE)
)
SELECT	
	AGENCY_AUTHORITY_NAME,
	ACCOUNTING_FISCAL_YEAR,
	FiscalMonth,
	AvgRevPerMon
FROM CTE 
	WHERE ColRank=1


--Showing the year with the highest total revenue for each Agency and Revenue Category. 
WITH CTE AS (
SELECT
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR,
	REVENUE_CATEGORY_DESC, 
	SUM(YTD_AMT) 
		OVER(PARTITION BY AGENCY_AUTHORITY_NAME, REVENUE_CATEGORY_DESC ORDER BY ACCOUNTING_FISCAL_YEAR) YearlyRevSum,
	RANK()
		OVER (PARTITION BY AGENCY_AUTHORITY_NAME, REVENUE_CATEGORY_DESC ORDER BY SUM(YTD_AMT) desc) ColRank
FROM YourMoney_Combined_Revenue
GROUP BY 
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR,
	REVENUE_CATEGORY_DESC, 
	YTD_AMT
)

SELECT 
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR,
	REVENUE_CATEGORY_DESC,
	FORMAT(YearlyRevSum, N'N2')  YearlyRevSum
FROM CTE
WHERE ColRank=1
ORDER BY 1, YearlyRevSum desc

--Yearly average revenue for each agency and category description, quartile rankings to more easily see trends. 

SELECT
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR,
	REVENUE_CATEGORY_DESC, 
	FORMAT(AVG(YTD_AMT), N'N2') AvgYearlyRev,
	NTILE(4) 
		OVER (PARTITION BY AGENCY_AUTHORITY_NAME, REVENUE_CATEGORY_DESC ORDER BY AVG(YTD_AMT) desc) Quartile
FROM YourMoney_Combined_Revenue
GROUP BY 
	AGENCY_AUTHORITY_NAME, 
	ACCOUNTING_FISCAL_YEAR,
	REVENUE_CATEGORY_DESC
HAVING AVG(YTD_AMT)>0 -- Cuts size of table nearly in half. 
ORDER BY 1,3,5

