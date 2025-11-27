--Aggregate Functions
Select * FROM [dbo].[EmployeeSalary]

--GIVES THE AVERAGE OF THE SALARY FIELD IN THE TABLE
SELECT AVG(SALARY) FROM EmployeeSalary

SELECT COUNT(SALARY) FROM EMPLOYEESALARY

Select SUM(SALARY) FROM EmployeeSalary

SELECT MIN(Salary) FROM EmployeeSalary 

SELECT MAX(Salary) FROM EmployeeSalary 

--ConCat: these are string functions which allow you to link values/text together.
Select  * from OrderNAme

--First establish the string
Print ConCat('String1', 'String2')

--concated text
SELECT OrderNo, OrderName, CONCAT(OrderName, ' ', OrderName) AS ConcatedText From OrderName

--Right: counts x number of characters from the right and then removes the rest
Select OrderNo,OrderName, Right( OrderNo, 2) AS NewOrders From OrderName

--Left: counts x number of characters from the left and then removes the rest 
Select Orderno, ORdername, Left(Orderno, 2, 