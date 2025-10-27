--Dates and GET DATES functions

--Select GETDATE()
select getdate()

--date minus 2 days
select getdate() -2 

--give me the number of years so and so has been with the company.

--GIVES YOU JUST YEAR
Select DATEPART(yyyy, Getdate()) as YEARNUMBER 

--GIVES YOU JUST MONTH
SELECT DATEPART(mm, GETDATE())

--GIVES YOU JUST THE DAY
SELECT DATEPART(dd, GETDATE()) 

--DATEADD

SELECT DATEADD(day, 4, getdate())

SELECT DATEADD(week, 8, GETDATE())

SELECT * FROM [Production].[WorkOrder]

SELECT workorderid, productID, StartDate, EndDate, DateDiff(day, Startdate, Enddate) From [Production].[WorkOrder]

--this formula allows you to pull up the first day of the month
SELECT DATEADD(dd, - (DATEPART(day, GETDATE()) -1), GETDATE())

