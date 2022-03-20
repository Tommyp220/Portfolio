
--Taking a look at the total amount of deaths from all causes in each jurisdiction in the 5 year span of 2014-2019

SELECT
Jurisdiction_of_Occurrence, 
FORMAT(Sum(All_cause),'N0') AllCauses
FROM [Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019]
GROUP BY Jurisdiction_of_Occurrence
ORDER BY Sum(All_cause) DESC


--Joining a table showing population estimates of the jursdictions using data from the census
--Comparing deaths from all causes to population based on year. 
SELECT
	Deaths.Jurisdiction_of_Occurrence, 
	MMWR_Year,
	FORMAT(SUM(All_cause),'N0') AllCauses,
	FORMAT(Pop.EstPopulation, 'N0') PopulationEstimate
FROM [Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019] Deaths
	JOIN [State Poptotal14-19] Pop
		ON Deaths.Jurisdiction_of_Occurrence=Pop.Location 
			AND Deaths.MMWR_Year=Pop."Year"
GROUP BY Jurisdiction_of_Occurrence, MMWR_Year, Pop.EstPopulation
ORDER BY Jurisdiction_of_Occurrence, MMWR_Year

--Comparing deaths from all causes to total population as a percentage.

WITH 
Causes AS 
(SELECT
	Deaths.Jurisdiction_of_Occurrence,
	MMWR_Year,
	SUM(All_cause) AllCauses
FROM [Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019] Deaths
GROUP BY Jurisdiction_of_Occurrence, MMWR_Year),

Populations AS (
SELECT
	Pop."Location", 
	Pop.EstPopulation, 
	Pop."Year"
FROM [State Poptotal14-19] Pop
GROUP BY Pop.Location, pop."Year", Pop.EstPopulation)

SELECT
	Causes.Jurisdiction_of_Occurrence,
	Causes.MMWR_Year,
	FORMAT(Causes.AllCauses, 'N0') AllCauses,
	FORMAT(Populations.EstPopulation, 'N0') EstPopulation,
	CONVERT(Decimal(18,3), (Causes.AllCauses *1.00/Populations.EstPopulation)*100) PercenOfPop
FROM Causes
	JOIN Populations
		ON Causes.Jurisdiction_of_Occurrence=Populations."Location"
		AND Causes.MMWR_Year=Populations."Year"
ORDER BY PercenOfPop desc

--Shows West Virgina has the overall highest percentage of deaths from all causes among all jurisdictions every year, which could be worth lookin into.  

--Comparing average deaths per year by state due to cancer to the average deaths due to cancer by state across all 2014-2019
WITH AvgByYear AS (SELECT 
	Jurisdiction_of_Occurrence,
	MMWR_Year,
	AVG(Malignant_neoplasms_C00_C97) AvgNumberCancerDeathsByYear
FROM [Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019] Deaths
GROUP BY Jurisdiction_of_Occurrence, MMWR_Year), 

AvgByLoc AS (
SELECT 
	Jurisdiction_of_Occurrence,
	AVG(Malignant_neoplasms_C00_C97) AvgNumberCancerDeathsByLoc
FROM [Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019] Deaths
GROUP BY Jurisdiction_of_Occurrence) 

SELECT 
	AvgByYear.Jurisdiction_of_Occurrence, 
	AvgByYear.MMWR_Year, 
	AvgNumberCancerDeathsByYear,
	AvgNumberCancerDeathsByLoc,
	(AvgNumberCancerDeathsByYear-AvgNumberCancerDeathsByLoc) DifferenceFromMean,
	CASE 
		WHEN AvgNumberCancerDeathsByLoc>AvgNumberCancerDeathsByYear 
			THEN 'More deaths than average'
			ELSE 'Less deaths than average'
		END HigherorLower
FROM AvgByYear JOIN AvgByLoc
	ON AvgByYear.Jurisdiction_of_Occurrence=AvgByLoc.Jurisdiction_of_Occurrence
