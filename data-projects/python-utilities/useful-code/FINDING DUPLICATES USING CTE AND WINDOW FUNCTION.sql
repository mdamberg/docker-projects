
USE [mytestdb]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
																/* 3 WAYS TO FIND AND REMOVE DUPLICATES  */
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


/**********************************************************************************************************************************************************************************************/ 
--1). DELETE USING BASIC SELECT, ORDER BY AND CTE
/**********************************************************************************************************************************************************************************************/


drop table if exists cars;
create table cars
(
	model_id		int primary key,
	model_name		varchar(100),
	color			varchar(100),
	brand			varchar(100)
);
insert into cars values(1,'Leaf', 'Black', 'Nissan');
insert into cars values(2,'Leaf', 'Black', 'Nissan');
insert into cars values(3,'Model S', 'Black', 'Tesla');
insert into cars values(4,'Model X', 'White', 'Tesla');
insert into cars values(5,'Ioniq 5', 'Black', 'Hyundai');
insert into cars values(6,'Ioniq 5', 'Black', 'Hyundai');
insert into cars values(7,'Ioniq 6', 'White', 'Hyundai');

select * from cars;


	/********************/
	-- REMOVE DUPLICATES
	/********************/

-- COUNT OF DUPLICATES

SELECT
	MODEL_NAME,
	COUNT(*) AS DUPLICATE_COUNT
FROM CARS
GROUP BY MODEL_NAME
HAVING COUNT(MODEL_NAME) > 1

-- DELETE USING ROW_NUM AND CTE

WITH CTE AS
(
	SELECT
		MODEL_NAME,
		ROW_NUMBER() OVER(PARTITION BY MODEL_NAME ORDER BY MODEL_NAME) AS ROW_NUMBER
	FROM CARS
)

DELETE 
FROM CTE
WHERE ROW_NUMBER > 1

					/********************************/
					-- DUPLICATES HAVE BEEN REMOVED
					/********************************/


/**********************************************************************************************************************************************************************************************/ 
--2). FINDING USING SUBQUERY
/**********************************************************************************************************************************************************************************************/

drop table if exists cars;
create table cars
(
	model_id		int primary key,
	model_name		varchar(100),
	color			varchar(100),
	brand			varchar(100)
);
insert into cars values(1,'Leaf', 'Black', 'Nissan');
insert into cars values(2,'Leaf', 'Black', 'Nissan');
insert into cars values(3,'Model S', 'Black', 'Tesla');
insert into cars values(4,'Model X', 'White', 'Tesla');
insert into cars values(5,'Ioniq 5', 'Black', 'Hyundai');
insert into cars values(6,'Ioniq 5', 'Black', 'Hyundai');
insert into cars values(7,'Ioniq 6', 'White', 'Hyundai');


	/*********************************************************/
		-- RETURNS THE COLUMNS WITH DUPLICATES
	/*********************************************************/

SELECT
	MODEL_NAME,
	COUNT(*) AS DUPLICATE_COUNT
FROM CARS
WHERE MODEL_NAME IN (SELECT	
						MODEL_NAME
					 FROM CARS
						GROUP BY MODEL_NAME
						HAVING COUNT(MODEL_NAME) > 1)

	/*********************************************************/
		-- RETURNS THE COUNT OF DUPLICATES
	/*********************************************************/

SELECT
	MODEL_NAME,
	COUNT(*) AS DUPLICATE_COUNT		-- ADD A COUNT(*) TO GET THE COUNT 
FROM CARS
WHERE MODEL_NAME IN (SELECT	
						MODEL_NAME
					 FROM CARS
						GROUP BY MODEL_NAME
						HAVING COUNT(MODEL_NAME) > 1)
GROUP BY MODEL_NAME						-- ADD A GROUP BY 


	/*********************************************************/
		-- DELETE STATEMENT USING EXISTS INSTEAD OF CTE
	/*********************************************************/


DELETE FROM CARS
WHERE EXISTS (			-- HERE WE USE EXIST TO CHECK FOR THE EXISTANCE OF ANOTHER another row with the same MODEL_NAME but a lower MODEL_ID
    SELECT 1
    FROM CARS AS C2
    WHERE CARS.MODEL_NAME = C2.MODEL_NAME
    AND CARS.MODEL_ID < C2.MODEL_ID  -- Assuming there is a unique identifier column (replace ID with the actual column name)
);


/**********************************************************************************************************************************************************************************************/ 
--3). FINDING DUPLICATES USING 
/**********************************************************************************************************************************************************************************************/

drop table if exists cars;
create table cars2
(
    id      int,
    model   varchar(50),
    brand   varchar(40),
    color   varchar(30),
    make    int
);
insert into cars2 values (1, 'Model S', 'Tesla', 'Blue', 2018);
insert into cars2 values (2, 'EQS', 'Mercedes-Benz', 'Black', 2022);
insert into cars2 values (3, 'iX', 'BMW', 'Red', 2022);
insert into cars2 values (4, 'Ioniq 5', 'Hyundai', 'White', 2021);
insert into cars2 values (1, 'Model S', 'Tesla', 'Blue', 2018);
insert into cars2 values (4, 'Ioniq 5', 'Hyundai', 'White', 2021);

select * from cars2

	
	/*********************************************************/
		-- RETURNS THE COUNT OF DUPLICATES
	/*********************************************************/	
	
SELECT
	ID,
	MODEL,
	COUNT(*) AS DUPLICATE_ROWS
FROM CARS2
GROUP BY ID, MODEL
HAVING COUNT(MODEL) > 1
	
	
	
	/*********************************************************/
		-- DELETE STATEMENT USING EXISTS INSTEAD OF CTE
	/*********************************************************/

WITH CTE AS 
(
SELECT
	ID,
	MODEL,
	ROW_NUMBER() OVER(PARTITION BY MODEL ORDER BY ID) AS DUP_RANK
FROM CARS2
)

DELETE FROM CTE
WHERE DUP_RANK > 1

SELECT * FROM CARS2