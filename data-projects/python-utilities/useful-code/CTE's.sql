--CTE Common table expressions
Select * from [Sales].[SalesTerritory]


WITH CTE_Salesterritory
AS 
(
	Select [Name], CountryRegionCode FROM sales.SalesTerritory
)

Select *  from CTE_salesterritory
Where [Name] like 'North%'; 



--fetch employees who earn more than averable salary of all employees

Select * from [dbo].[EmployeeSalary]
Where salary > avergage_salary; --WE DONT HAVE A COLUMN FOR THIS SO WE NEED TO MAKE A CTE

WITH CTE_AvgSalary
AS
(
Select AVG(salary)as average_salary FROM [dbo].[EmployeeSalary]
)

Select * from [dbo].[EmployeeSalary], CTE_AvgSalary		--MAKE SURE TO ADD THE CTE'S NAME TO THE FROM CLAUSE
Where Salary > average_salary

--FIND sales person WHOS SALES WERE BETTER THAN THE AVERAGE SALEs ACROSS ALL people

	SELECT TOP (1000) [FirstName]
      ,[LastName]
      ,[SalesLastYear]
      ,[LastYearsSales]
  FROM [AdventureWorks2022].[Sales].[vSalesPerson_2]

  --1) find the total sales for each person

  Select CONCAT(firstname, ' ', lastname) AS fullname, saleslastyear FROM [Sales].[vSalesPerson_2]

  --2) find the average sales with respect to all salesmen

Select avg([SalesLastYear]) AS total_AVG_SalesLY

FROM (Select CONCAT(firstname, ' ', lastname) AS fullname, saleslastyear 
	FROM [Sales].[vSalesPerson_2]
	group by FirstName, LastName, SalesLastYear) x

	--3) Find the salesman where totalsales > average sales

--first without WITH
	
SELECT *
FROM (Select CONCAT(firstname, ' ', lastname) AS fullname, saleslastyear 
	FROM [Sales].[vSalesPerson_2]
	group by FirstName, LastName, SalesLastYear) total_sales
JOIN
(Select avg([SalesLastYear]) AS total_AVG_SalesLY

FROM (Select CONCAT(firstname, ' ', lastname) AS fullname, saleslastyear 
	FROM [Sales].[vSalesPerson_2]
	group by FirstName, LastName, SalesLastYear) x) avg_sale
ON total_AVG_SalesLY > total_AVG_SalesLY


--/////////////////------//////////////////////////////------////////////////////
--Group by --> group all of these queries together-->  to do so they all must have the same # of columns so add NULLS

Select * from [Sales].[SalesTerritory]

SELECT
	[name], 
	SUM(SalesYTD) as total_YTD
	, Null
	, Null
FROM [Sales].[SalesTerritory]
Group by name 

Union ALL

Select 
	[name]
	,SUM(SALESYTD) as total_YTD
	,countryregioncode
	, Null
FROM [Sales].[SalesTerritory]
Group by [name], CountryRegionCode

UNION ALL

Select 
	[name] 
	, SUM(SALESYTD) as total_YTD
	, countryregioncode
	, [Group]
FROM [Sales].[SalesTerritory]
Group by [name], CountryRegionCode, [Group]


--Grouping Sets--> easier than above

Select 
	[name] 
	, SUM(SALESYTD) as total_YTD
	, countryregioncode
	, [Group]
FROM [Sales].[SalesTerritory]
Group by grouping SETS
(
	([Name]), 
	([Name], CountryRegionCode),
	([Name], CountryRegionCode, [Group])
)

--ROLLUP  --> will do the same thing as above but will start with the super set and auto work down

Select 
	[name] 
	, SUM(SALESYTD) as total_YTD
	, countryregioncode
	, [Group]
FROM [Sales].[SalesTerritory]
Group by ROLLUP
(

	([Name], CountryRegionCode, [Group])
)

--CUBE  does the same thing as above??

Select 
	[name] 
	, SUM(SALESYTD) as total_YTD
	, countryregioncode
	, [Group]
FROM [Sales].[SalesTerritory]
Group by CUBE
(

	([Name], CountryRegionCode, [Group])
)

--MORE CTE PRACTICE
Select * from [Production].[Product]


--1. Find the average cost of standard cost less the list price. 
/////////////
With CTEProfit_Margin 
AS 
(
Select ProductID, [name], AVG((ListPrice) - (StandardCost)) AS Profit_margin
FROM [Production].[Product]
GROUP BY [ProductID], [Name]
)

Select AVG(profit_margin) as AVG_Profit_Margin from CTEProfit_Margin



--2 Fetch total number of businesses with credit rating greater or equal to 4, no active red flags and the day and month
///////////////

Select * from [Purchasing].[Vendor]

WITH CTE_CreditRating
AS
(
Select CreditRating, ActiveFlag FROM [Purchasing].[Vendor]
	Where CreditRating>= 4
	AND ActiveFlag = 0
)
Select Count (distinct BusinessEntityID) AS Total_Num_Businesses
FROM [Purchasing].[Vendor]
Group by [BusinessEntityID]