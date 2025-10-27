-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------  Pizza Runners  ------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* -----------------
-----SCHEMA---------
-------------------*/

CREATE SCHEMA pizza_runner2;
SET search_path = pizza_runner2.0;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

------------------------------------------------------------------------------------------------------
--WE CANNOT insert an explicit value into a timestamp column IN THE TABLE BELOW.
--WE ALSO CANNOT CHANGE DATA TYPE FROM TIMESTAMP TO DATE TIME
--SO WE WILL CREATE A NEW COLUMN OF DATETIME TYPE, ADD ORIGINAL COLUMN DATA TO IT AND DROP OLD COLUMN
------------------------------------------------------------------------------------------------------

--ADD A NEW DATETIME COLUMN
  ALTER TABLE [dbo].[customer_orders]
  ADD [order_time_NEW] DATETIME;

  -- COPY VALUES FROM OLD COLUMN  INTO NEW
UPDATE [dbo].[customer_orders]
SET [order_time_NEW] = [order_time];

-- DROP ORIGINAL COLUMN
ALTER TABLE [dbo].[customer_orders]
DROP COLUMN [order_time]

--RENAME NEW COLUMN TO OLD COLUMN
EXEC SP_RENAME 'customer_orders.ORDER_TIME_NEW', 'order_time', 'COLUMN';


INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');


--------------------------------------------------------------------------------------------------------------------------------
---DATA CLEANING---
--------------------------------------------------------------------------------------------------------------------------------


SELECT * FROM [dbo].[customer_orders]
SELECT * FROM [dbo].[pizza_names]
SELECT * FROM [dbo].[pizza_recipes]
SELECT * FROM [dbo].[pizza_toppings]
SELECT * FROM[dbo].[runner_orders]
SELECT * FROM [dbo].[runners]


/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--CUSTOMER ORDERS TABLE--
////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

/*//////////////////////////////
--EXCLUSION COLUMN
///////////////////////////// */

-- CHANGNING STRING NULLS TO EMPTY FOR CONSISTENCY
UPDATE [dbo].[customer_orders]
SET EXCLUSIONS = 
	CASE
      WHEN exclusions is null OR exclusions = 'null' THEN ' '
      ELSE exclusions
    END

/*//////////////////////////////
--EXTRAS COLUMN
///////////////////////////// */

--CHANGING STRING NULLS TO EMPTY FOR CONSISTENCY
UPDATE [dbo].[customer_orders]
SET EXTRAS = 
	CASE
		WHEN EXTRAS = 'null' THEN ' '	
		ELSE EXTRAS
	END


/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--RUNNER_ORDERS TABLE--
///////////////////////////////////////////////////////////////////////////////////////////////////////////// */ 


/*//////////////////////////////
--PICK UP COLUMN
///////////////////////////// */ 

--ADD A NEW DATETIME COLUMN AS WE CANNOT CONVERT TIMESTAMP TO DATETIME
 ALTER TABLE [dbo].[runner_orders]
 ADD [pickup_time_NEW] DATETIME;


-- COPY VALUES FROM OLD COLUMN INTO NEW
UPDATE [dbo].[runner_orders]
SET [pickup_time_NEW] = 
	CASE
		WHEN ISDATE([pickup_time]) = 1 THEN TRY_CAST([pickup_time] AS DATETIME)
		ELSE NULL
	END;


-- DROP ORIGINAL COLUMN
ALTER TABLE [dbo].[runner_orders]
DROP COLUMN [pickup_time]

--RENAME NEW COLUMN TO OLD COLUMN
EXEC SP_RENAME 'runner_orders.pickup_TIME_NEW', 'pickup_time', 'COLUMN';


	/*//////////////////////////////
	--DURATION COLUMN
	///////////////////////////// */ 

--REMOVING MINUTES LABEL FROM VALUES

UPDATE [dbo].[runner_orders]
SET [duration] = 
	CASE
		WHEN DURATION = 'null' THEN ' '
		WHEN DURATION LIKE '%mins' THEN TRIM('mins' from duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
		ELSE duration
	 END;


--CHANGING STRING NULLS TO BLANKS

UPDATE [dbo].[runner_orders]
SET [duration] = 
	CASE
		WHEN DURATION = 'null' THEN ' '
	END;

	/*//////////////////////////////
	--DISTANCE COLUMN
	///////////////////////////// */ 

--CHANGING STRING NULLS TO BLANKS AND REMOVING KM LABEL

UPDATE [dbo].[runner_orders]
SET [distance] = 
	CASE 
			WHEN DISTANCE = 'null' THEN 'NULL'
			WHEN DISTANCE LIKE '%km' THEN TRIM('km' from distance)
			ELSE DISTANCE
		END;

--CHANGING CAPITAL STRING NULLS TO BLANKS 

UPDATE [dbo].[runner_orders]
SET DISTANCE = 
	CASE
		WHEN DISTANCE = 'NULL' THEN ' '
		ELSE DISTANCE 
	END


	/*//////////////////////////////
	--CANCELLATION COLUMN
	///////////////////////////// */

/*--CHANGING CANELLATION DATATYPE FROM VARCHAR TO INT--*/ 
----------------------------------------------------

--1. ADD NEW INT COLUMN

ALTER TABLE [dbo].[runner_orders]
ADD [cancellation_NEW] INT;


--2. UPDATE NEW COLUMN WITH CONVERTED VALUES

UPDATE [dbo].[runner_orders]
SET [cancellation_new] = CASE 
    WHEN ISNUMERIC([cancellation]) = 1 THEN CAST([cancellation] AS INT)
    ELSE 0  -- Set a default value for non-integer values, you can change this to another integer value if needed
    END;


--3. DROP OLD VARCHAR COLUMN

ALTER TABLE [dbo].[runner_orders]
DROP COLUMN [cancellation];


--4. RENAME NEW COLUMN TO MATCH ORIGNAL NAME

EXEC SP_RENAME 'runner_orders.cancellation_new', ' cancellation', 'COLUMN'; 


--CHANGING STRING NULL'S TO BLANKS--

UPDATE [dbo].[runner_orders]
SET CANCELLATION = 
	CASE
		WHEN CANCELLATION = 'null' THEN ' ' 
		ELSE CANCELLATION 
	END;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--PIZZA NAMES TABLE--
///////////////////////////////////////////////////////////////////////////////////////////////////////////// */ 

	/*//////////////////////////////
	--PIZZA_NAME COLUMN
	///////////////////////////// */

--CONVERTING PIZZA NAME FROM TEXT TO VARCHAR

ALTER TABLE [dbo].[pizza_names]
ALTER COLUMN [pizza_name] VARCHAR (255)


/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--PIZZA TOPPINGS TABLE--
///////////////////////////////////////////////////////////////////////////////////////////////////////////// */ 

	/*//////////////////////////////
	--TOPPING_NAME COLUMN
	///////////////////////////// */

ALTER TABLE [dbo].[pizza_toppings]
ALTER COLUMN TOPPING_NAME VARCHAR(255)

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--PIZZA RECIPIES TABLE--
///////////////////////////////////////////////////////////////////////////////////////////////////////////// */ 

ALTER TABLE [dbo].[pizza_recipes]
ALTER COLUMN TOPPINGS VARCHAR (255)


/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////
										--CASE STUDY QUESTIONS--
///////////////////////////////////////////////////////////////////////////////////////////////////////////// */ 


--------------------
 -- A. Pizza Metrics
--------------------
-- 1. How many pizzas were ordered?
-- 2. How many unique customer orders were made?
-- 3. How many successful orders were delivered by each runner?
-- 4. How many of each type of pizza was delivered?
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10.What was the volume of orders for each day of the week?

SELECT * FROM [dbo].[customer_orders]
SELECT * FROM [dbo].[pizza_names]
SELECT * FROM [dbo].[pizza_recipes]
SELECT * FROM [dbo].[pizza_toppings]
SELECT * FROM [dbo].[runner_orders]
SELECT * FROM [dbo].[runners]

--------------------------------------------------------------------------------------------------------------
--1. How many pizzas were ordered?
--------------------------------------------------------------------------------------------------------------


SELECT 
	COUNT(*) AS TOTAL_PIZZAS
FROM [dbo].[customer_orders]


--------------------------------------------------------------------------------------------------------------
-- 2. How many unique customer orders were made?
--------------------------------------------------------------------------------------------------------------


SELECT
	COUNT(DISTINCT ORDER_ID)AS UNIQUE_ORDERS
FROM [dbo].[customer_orders]


--------------------------------------------------------------------------------------------------------------
-- 3. How many successful orders were delivered by each runner?
--------------------------------------------------------------------------------------------------------------

SELECT * FROM [dbo].[runner_orders]

SELECT 
	RUNNER_ID,
	COUNT(RUNNER_ID) AS ORDER_COUNT		
FROM [dbo].[runner_orders]
WHERE DISTANCE <> ' '
GROUP BY RUNNER_ID

--------------------------------------------------------------------------------------------------------------
-- 4. How many of each type of pizza was delivered?
--------------------------------------------------------------------------------------------------------------

SELECT
	CAST(PIZZA_NAME AS VARCHAR(255)) AS Pizza_Name,	--CAST AS VARCHAR TO AVOID DATA TYPE COMPARISON ERROR
	COUNT(PN.PIZZA_ID) AS PIZZA_DELIVERED
FROM [dbo].[runner_orders] RO 
JOIN CUSTOMER_ORDERS C ON RO.ORDER_ID = C.ORDER_ID
JOIN PIZZA_NAMES PN ON C.PIZZA_ID = PN.PIZZA_ID
WHERE DISTANCE IS NOT NULL
GROUP BY CAST(PIZZA_NAME AS VARCHAR(255))

--------------------------------------------------------------------------------------------------------------
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
--------------------------------------------------------------------------------------------------------------

SELECT
	CUSTOMER_ID,
	PIZZA_NAME,
	COUNT(PIZZA_NAME) AS PIZZA_COUNT
FROM [dbo].[customer_orders] C
JOIN [dbo].[pizza_names] P ON C.PIZZA_ID = P.PIZZA_ID
WHERE PIZZA_NAME IN ('Vegetarian', 'Meatlovers') 
GROUP BY CUSTOMER_ID, PIZZA_NAME
ORDER BY CUSTOMER_ID

--------------------------------------------------------------------------------------------------------------
-- 6. What was the maximum number of pizzas delivered in a single order?
--------------------------------------------------------------------------------------------------------------

SELECT
	TOP 1 ORDER_ID,
	COUNT(ORDER_ID) AS MAX_PIZZA
FROM [dbo].[customer_orders]
GROUP BY ORDER_ID
ORDER BY MAX_PIZZA DESC
 

 -- MULTIPLE QUESTIONS HAVE ASKED TO JOIN CUSTOMER ORDERS WITH RUNNER ORDERS. 
 -- VIEW CREATED FOR EFFICIENCY

CREATE VIEW DELIVERED_ORDERS AS 
SELECT
	C.ORDER_ID,
	C.CUSTOMER_ID,
	C.PIZZA_ID,
	C.EXCLUSIONS,
	C.EXTRAS,
	C.order_time,
	R.RUNNER_ID,
	R.PICKUP_TIME,
	R.DISTANCE,
	R.DURATION, 
	R.CANCELLATION
FROM CUSTOMER_ORDERS C
JOIN RUNNER_ORDERS R ON 
	C.ORDER_ID = R.ORDER_ID


SELECT * FROM DELIVERED_ORDERS

 --------------------------------------------------------------------------------------------------------------
 -- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--------------------------------------------------------------------------------------------------------------

SELECT
	CUSTOMER_ID,
	SUM(
		CASE
			WHEN EXCLUSIONS <> ' ' OR EXTRAS <> ' ' THEN 1 
			ELSE 0
				END) AS CHANGES,
	SUM(
		CASE 
			WHEN EXCLUSIONS = ' ' AND EXTRAS = ' '  OR EXTRAS IS NULL THEN 1 
			ELSE 0
				END) AS NO_CHANGES
FROM DELIVERED_ORDERS
WHERE PICKUP_TIME IS NOT NULL
GROUP BY CUSTOMER_ID
ORDER BY CUSTOMER_ID

--------------------------------------------------------------------------------------------------------------
-- 8. How many pizzas were delivered that had both exclusions and extras?
--------------------------------------------------------------------------------------------------------------
SELECT * FROM DELIVERED_ORDERS

SELECT
	COUNT(ORDER_ID) AS PIZZA_COUNT 
FROM DELIVERED_ORDERS
WHERE EXCLUSIONS <> ' '
AND EXTRAS <> ' '
AND CANCELLATION = ' '


--------------------------------------------------------------------------------------------------------------
-- 9. What was the total volume of pizzas ordered for each hour of the day?
--------------------------------------------------------------------------------------------------------------

SELECT
	COUNT(PIZZA_ID) AS PIZZAS_PER_HOUR,
	DATEPART(HOUR, ORDER_TIME) AS HOUR_OF_DAY		
FROM DELIVERED_ORDERS 
GROUP BY DATEPART(HOUR, ORDER_TIME)


--------------------------------------------------------------------------------------------------------------
-- 10.What was the volume of orders for each day of the week?
--------------------------------------------------------------------------------------------------------------

SELECT
	DATENAME(WEEKDAY, ORDER_TIME) AS WEEK_DAY,
	COUNT(ORDER_ID) AS ORDER_VOLUME								
FROM DELIVERED_ORDERS
GROUP BY DATENAME(WEEKDAY, ORDER_TIME)
ORDER BY WEEK_DAY


--------------------------------------
 -- B. Runner And Customer Experience
--------------------------------------
--1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
--4. What was the average distance travelled for each customer?
--5. What was the difference between the longest and shortest delivery times for all orders? 
--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
--7. What is the successful delivery percentage for each runner?



--------------------------------------------------------------------------------------------------------------
-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--------------------------------------------------------------------------------------------------------------

SET DATEFIRST 1;	--SETS FIRST DAY OF WEEK TO MONDAY (SQL DEFAULT IS SUNDAY)

SELECT
	DATEPART(WEEK, REGISTRATION_DATE) AS WEEK_OF_YEAR,
	COUNT(RUNNER_ID) AS RUNNER_COUNT
FROM [dbo].[runners]
GROUP BY DATEPART(WEEK, REGISTRATION_DATE)


------------------------------------------------------------------------------------------------------------------------
--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
------------------------------------------------------------------------------------------------------------------------

-- CREATE CTE TO USE DATEFIFF TO GET DIFFERENCE BETWEEN ORDER TIME AND PICK UP TIME IN MIN

WITH TIME_TABLE AS
(
SELECT
	RUNNER_ID,
	DATEDIFF(MINUTE, ORDER_TIME, PICKUP_TIME) AS TIME
FROM DELIVERED_ORDERS
WHERE CANCELLATION IS NULL
OR CANCELLATION = ' '
)

SELECT
	RUNNER_ID,
	CONCAT(AVG(TIME), ' ', 'Mins') AS AVERAGE_TIME	--AVERAGE OF DIFF BETWEEN ORDER AND PICK UP TIME
FROM TIME_TABLE
GROUP BY RUNNER_ID


----------------------------------------------------------------------------------------------------
--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
----------------------------------------------------------------------------------------------------

WITH TIME_TABLE AS
(
SELECT
	ORDER_ID,
	COUNT(ORDER_ID) AS PIZZA_COUNT,
	DATEDIFF(MINUTE, ORDER_TIME, PICKUP_TIME) AS TIME
FROM DELIVERED_ORDERS
WHERE CANCELLATION IS NULL
OR CANCELLATION = ' '
GROUP BY ORDER_ID, PICKUP_TIME, ORDER_TIME
)

SELECT
	PIZZA_COUNT,
	AVG(TIME) AS AVERAGE_TIME	--AVERAGE OF DIFF BETWEEN ORDER AND PICK UP TIME
FROM TIME_TABLE
GROUP BY PIZZA_COUNT
ORDER BY AVERAGE_TIME


---------------------------------------------------------------
--4. What was the average distance travelled for each customer?
---------------------------------------------------------------


SELECT
    CUSTOMER_ID,
    ROUND(AVG(CONVERT(FLOAT, DISTANCE)),2) AS AVG_DISTANCE
FROM DELIVERED_ORDERS
GROUP BY CUSTOMER_ID
ORDER BY AVG_DISTANCE DESC


--------------------------------------------------------------------------------------------------------------
--5. What was the difference between the longest and shortest delivery times for all orders? 
--------------------------------------------------------------------------------------------------------------

SELECT
	MAX(duration) - MIN(duration) as DURATION_DIFF
FROM [dbo].[runner_orders]


---------------------------------------------------------------------------------------------------------------
--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
---------------------------------------------------------------------------------------------------------------

SELECT * FROM DELIVERED_ORDERS

SELECT
	RUNNER_ID, 
	ORDER_ID,
	ROUND(AVG(CAST(DISTANCE AS FLOAT) / DURATION),2) * 60 AS AVG_SPEED
FROM DELIVERED_ORDERS
WHERE DURATION IS NOT NULL
GROUP BY RUNNER_ID, ORDER_ID
ORDER BY RUNNER_ID


-----------------------------------------------------------------
--7. What is the successful delivery percentage for each runner?
-----------------------------------------------------------------

SELECT RUNNER_ID, CANCELLATION FROM DELIVERED_ORDERS;

WITH CTE AS 
(
    SELECT
        RUNNER_ID,
        SUM(CASE 
            WHEN CANCELLATION = ' ' OR CANCELLATION IS NULL THEN 1
            ELSE 0
        END) AS NUM_NOT_CANCELED,
        COUNT(RUNNER_ID) AS TOTAL
    FROM DELIVERED_ORDERS
    GROUP BY RUNNER_ID
)

SELECT
    RUNNER_ID, 
    CONVERT(DECIMAL(18, 2), CAST(NUM_NOT_CANCELED AS DECIMAL) / CAST(TOTAL AS DECIMAL) * 100) AS PERCENTAGE_SUCCESS
FROM CTE;


------------------------------
 -- C. INGREDIENT OPTIMIZATION
------------------------------

--1. What are the standard ingredients for each pizza?
--2. What was the most commonly added extra?
--3. What was the most common exclusion?
--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
		--Meat Lovers
		--Meat Lovers - Exclude Beef
		--Meat Lovers - Extra Bacon
		--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?




------------------------------------------------------
--1. What are the standard ingredients for each pizza?
------------------------------------------------------

--THE RESULTS FOR THE COLUMN TOPPINGS IS LISTED AS COMMA SEPARATED STRING (1,2,3,4,5) AND NEEDS TO BE SPLIT

-------------------------------------
--SPLITTING THE RESULTS OF TOPPINGS 
-------------------------------------

-- Create a temporary table to hold the results
CREATE TABLE #Toppings (Topping_ID int, Topping int)

	-- Split the comma-separated values and insert into the temporary table
	INSERT INTO #Toppings (Topping_ID, Topping)
	SELECT PIZZA_ID, value AS Toppings
	FROM [dbo].[pizza_recipes]
	CROSS APPLY STRING_SPLIT(Toppings, ',')

	-- Select the results
	SELECT * FROM #Toppings

		/* NOW THAT WE HAVE THE SPLIT VALUES, LETS CREATE AN ADDITIONAL TEMP TABLE THAT JOINS THAT FIRST TEMP TABLE WITH THE PIZZA TOPPINGS TABLE 
		GIVING US THE JOINED RESULT SET OF THE SPLIT TOPPINGS, TOPPING_ID AND THE TOPPING_NAME */

--CREATE NEW TEMP TABLE
CREATE TABLE #INGREDIENTS (TOPPING_ID INT, TOPPING INT, TOPPING_NAME VARCHAR(255))

	--INSERT JOIN STATEMENT INTO TEMP TABLE
	INSERT INTO #INGREDIENTS
	SELECT
		T.TOPPING_ID,					
		T.TOPPING,
		PT.TOPPING_NAME
	FROM #Toppings T LEFT JOIN [dbo].[pizza_toppings] PT ON
		T.TOPPING = PT.TOPPING_ID



-----------------------------------------------------
--PUT THE ABOVE CODE IN A STORED PROCEDURE FOR EASE 
-----------------------------------------------------

CREATE PROCEDURE PIZZA_INGREDIENTS
AS 
BEGIN
    -- Create a temporary table to hold the results
    create TABLE #Toppings (PIZZA_ID int, Topping int)

    -- Split the comma-separated values and insert into the temporary table
    INSERT INTO #Toppings (PIZZA_ID, Topping)
    SELECT 
		PIZZA_ID, 
	 value AS SPLIT_TOPPINGS
	FROM customer_orders
	CROSS APPLY (
		VALUES
			(SUBSTRING(extras, 1, CHARINDEX(',', extras + ',') - 1)),
			(SUBSTRING(extras, CHARINDEX(',', extras + ',') + 1, LEN(extras)))
				) AS SplitValues(value);

				SELECT * FROM #Toppings

    -- Now that we have the split values, create another temporary table
    CREATE TABLE #INGREDIENTS (PIZZA_ID INT, TOPPING INT, TOPPING_NAME VARCHAR(255));

    -- Insert join statement into the second temporary table
    INSERT INTO #INGREDIENTS
    SELECT
        T.PIZZA_ID,
        T.TOPPING,
        PT.TOPPING_NAME
    FROM #Toppings T
    LEFT JOIN [dbo].[pizza_toppings] PT ON T.TOPPING = PT.TOPPING_ID;
END;


/*////////////////////////// */
EXEC PIZZA_INGREDIENTS				--NOW WE CAN JUST RUN THIS STORED PROCEDURE EACH TIME WE OPEN THE FILE AND THE TEMP TABLES WILL BE CREATED, BUT THERE IS STILL A BETTER WAY
/*////////////////////////// */		
	
	SELECT * FROM #Toppings
	SELECT * FROM #INGREDIENTS


--------------------------------------------------------------------------------------------------------------------------------
-- CREATE A START UP PROCEDURE WHICH WILL AUTOMATICALLY RUN OUR PIZZA_INGREDIENTS STORED PROCEDURE WHEN THIS DATABASE IS OPENED
--------------------------------------------------------------------------------------------------------------------------------

-- Create your startup stored procedure
CREATE PROCEDURE StartupProcedure
AS
BEGIN
    -- Your code here, in this case, we'll call your PIZZA_INGREDIENTS procedure
    EXEC PIZZA_INGREDIENTS;
END;

-- Configure the startup procedure
EXEC sp_procoption 'StartupProcedure', 'STARTUP', 'ON';

------------------------------------------------------
--1. What are the standard ingredients for each pizza?
------------------------------------------------------


SELECT
        T.TOPPING_ID AS PIZZA_ID, 
        T.TOPPING,
        PT.TOPPING_NAME
    FROM #Toppings T
    LEFT JOIN [dbo].[pizza_toppings] PT ON T.TOPPING = PT.TOPPING_ID

-- MEATLOVERS: BACON, BBQ SAUCE, BEEF, CHEESE, CHICKEN, MUSHROOMS, PEPPERONI, SALAMI
-- VEGETARIAN: CHEESE, MUSHROOMS, ONIONS, PEPPERS, TOMATOES, TOMATO SAUCE


------------------------------------------------------
--2. What was the most commonly added extra?
------------------------------------------------------

--CREATE 2 TEMP TABLES TO MAKE SPLITTING VALUES IN EXTRAS AND JOINING PIZZA_TOPPINGS EASIER

 -- Create a temporary table to hold the results
    CREATE TABLE #SplitToppings (PIZZA_ID int, Toppings int)

    -- Split the comma-separated values and insert into the temporary table
    INSERT INTO #SplitToppings (PIZZA_ID, Toppings)
		SELECT
		 PIZZA_ID,
		 TRIM(VALUE) AS TOPPING_SPLIT
		FROM pizza_recipes
		CROSS APPLY STRING_SPLIT(TOPPINGS, ',');


-- CREATE TEMP TABLE FOR SPLIT EXCLUSION VALUES
CREATE TABLE #SPLIT_EXCLUSIONS (PIZZA_ID INT, EXCLUSIONS INT)

INSERT INTO #SPLIT_EXCLUSIONS
	SELECT
		PIZZA_ID,
		TRIM(VALUE) AS EXCLUSIONS_SPLIT
	FROM CUSTOMER_ORDERS
	CROSS APPLY STRING_SPLIT(EXCLUSIONS, ',')


-- create temp table for splitting extras
	CREATE TABLE #SPLIT_EXTRAS (PIZZA_ID INT, EXTRAS_SPLIT INT)
		
	INSERT INTO #SPLIT_EXTRAS
	SELECT
		 PIZZA_ID,
		 TRIM(VALUE) AS EXTRAS_SPLIT
		FROM customer_orders 
		CROSS APPLY STRING_SPLIT(extras, ',')


-- SPLIT TOPPINGS: THIS WORKS
	SELECT 
		PIZZA_ID, 
	 value AS SPLIT_TOPPINGS
	FROM customer_orders
	CROSS APPLY (
		VALUES
			(SUBSTRING(extras, 1, CHARINDEX(',', extras + ',') - 1)),
			(SUBSTRING(extras, CHARINDEX(',', extras + ',') + 1, LEN(extras)))
				) AS SplitValues(value);


    -- Now that we have the split values, create another temporary table
    CREATE TABLE #INGREDIENTS (PIZZA_ID INT, TOPPING INT, TOPPING_NAME VARCHAR(255));

    -- Insert join statement into the second temporary table
    INSERT INTO #INGREDIENTS
    SELECT
        T.PIZZA_ID,
        T.TOPPING,
        PT.TOPPING_NAME
    FROM #Toppings T
    LEFT JOIN [dbo].[pizza_toppings] PT ON T.TOPPING = PT.TOPPING_ID;


SELECT 
	COUNT(TOPPING) AS TOPPING_COUNT,
	TOPPING_NAME
FROM #INGREDIENTS	
WHERE TOPPING_NAME IS NOT NULL
GROUP BY TOPPING_NAME

-----------------------------------------------------
--3. What was the most common exclusion?
-----------------------------------------------------

SELECT
	*
FROM CUSTOMER_ORDERS C
	JOIN [dbo].[pizza_recipes] R ON 
		C.PIZZA_ID = R.PIZZA_ID
	JOIN [dbo].[pizza_toppings] T ON
		R.

SELECT * FROM customer_orders
--SELECT * FROM pizza_toppings
SELECT * FROM #Toppings
SELECT * FROM [dbo].[pizza_recipes]
---------------------------------------------------------------------------------------------------------------
--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
----------------------------------------------------------------------------------------------------------------
		--Meat Lovers

SELECT 
	*
FROM [dbo].[customer_orders] C JOIN [dbo].[pizza_names] N
	ON C.PIZZA_ID = N.PIZZA_ID
WHERE C.PIZZA_ID = 1

		--Meat Lovers - Exclude Beef

SELECT
	* 
FROM [dbo].[customer_orders] C 
JOIN [dbo].[pizza_names] N
	ON C.PIZZA_ID = N.PIZZA_ID
JOIN [dbo].[pizza_toppings] T 
	ON C.PIZZA_ID = T.TOPPING_ID
WHERE C.PIZZA_ID =1
AND TOPPING_NAME <> 'Beef'
		
		--Meat Lovers - Extra Bacon

SELECT
	* 
FROM [dbo].[customer_orders] C 
JOIN [dbo].[pizza_names] N
	ON C.PIZZA_ID = N.PIZZA_ID			--NOT DONE
JOIN [dbo].[pizza_toppings] T 
	ON C.PIZZA_ID = T.TOPPING_ID
JOIN [dbo].[pizza_recipes] R
	ON C.PIZZA_ID = R.PIZZA_ID
CROSS APPLY STRING_SPLIT (R.TOPPINGS, ',')
WHERE C.PIZZA_ID =1
AND EXTRAS = 1

		--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--D. Pricing and Ratings
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--1). If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

	SELECT
		COUNT( ORDER_ID) AS TOTAL_ORDERS
	FROM customer_orders
--------------------------
	-- 14 TOTAL ORDERS
--------------------------

SELECT
	SUM(	
		CASE WHEN PIZZA_NAME = 'Meatlovers' THEN 1 ELSE 0 END) AS MEATLOVERS_TOTAL,
	SUM(
		CASE WHEN PIZZA_NAME = 'Vegetarian' THEN 1 ELSE 0 END) AS VEGETARIAN_TOTAL
FROM CUSTOMER_ORDERS C
	JOIN [dbo].[pizza_names] N ON 
		C.PIZZA_ID = N.PIZZA_ID

--------------------------
-- 10 MEAT LOVERS ORDERED 
-- 4 VEGETARIAN ORDERED 
--------------------------

WITH REVENUE AS
(
	SELECT
		SUM(
			CASE WHEN PIZZA_NAME = 'Meatlovers' THEN 1 ELSE 0 END) * 12 AS MEATLOVER_REV,
		SUM(
			CASE WHEN PIZZA_NAME = 'Vegetarian' THEN 1 ELSE 0 END) * 10 AS VEGETARIAN_REV
	FROM CUSTOMER_ORDERS C
	JOIN [dbo].[pizza_names] N ON 
		C.PIZZA_ID = N.PIZZA_ID
)
SELECT
	MEATLOVER_REV,
	VEGETARIAN_REV,
	(MEATLOVER_REV + VEGETARIAN_REV) AS TOTAL_REVENUE
FROM REVENUE


--2).What if there was an additional $1 charge for any pizza extras?
	
WITH REVENUE AS
(
	SELECT
		SUM(
			CASE 
				WHEN PIZZA_NAME = 'Meatlovers' THEN 1 
				WHEN EXTRAS <> ' ' THEN 1 ELSE 0 END) * 12 AS MEATLOVER_REV,
		SUM(
			CASE 
				WHEN PIZZA_NAME = 'Vegetarian' THEN 1 
				WHEN EXTRAS <> ' ' THEN 1 ELSE 0 END) * 10 AS VEGETARIAN_REV
	FROM CUSTOMER_ORDERS C
	JOIN [dbo].[pizza_names] N ON 
		C.PIZZA_ID = N.PIZZA_ID
)
SELECT
	MEATLOVER_REV,
	VEGETARIAN_REV,
	(MEATLOVER_REV + VEGETARIAN_REV) AS TOTAL_REVENUE
FROM REVENUE
	
		--------------------------------------
			--Add cheese is $1 extra
		--------------------------------------

		WITH REVENUE AS
		(
			SELECT
				C.PIZZA_ID,
				SUM(
					CASE WHEN PIZZA_NAME = 'Meatlovers' THEN 1 ELSE 0 END) * 12 AS MEATLOVER_REV,
				SUM(
					CASE WHEN PIZZA_NAME = 'Vegetarian' THEN 1 ELSE 0 END) * 10 AS VEGETARIAN_REV
			FROM CUSTOMER_ORDERS C
			JOIN [dbo].[pizza_names] N ON 
				C.PIZZA_ID = N.PIZZA_ID
			GROUP BY C.PIZZA_ID
		),

		CHEESE AS
		(
			SELECT
				SUM(
					CASE WHEN EXTRAS_SPLIT = 4 THEN MEATLOVER_REV + 1 ELSE 0 END) AS MEAT_CHEESE,
				SUM(
					CASE WHEN EXTRAS_SPLIT = 4  AND R.PIZZA_ID = 2 THEN (VEGETARIAN_REV + 1) ELSE VEGETARIAN_REV END) AS VEG_CHEESE		--THIS IS CAUSING THE ISSUE
			FROM REVENUE R JOIN #SPLIT_EXTRAS S ON
				R.PIZZA_ID = S.PIZZA_ID
		)

		SELECT
			MEAT_CHEESE,
			VEG_CHEESE,
			MEAT_CHEESE + VEG_CHEESE AS CHEESE_REV
		FROM CHEESE

SELECT * FROM #SPLIT_EXTRAS



	SELECT * FROM customer_orders
	SELECT * FROM #SPLIT_EXTRAS

--3). The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset 
	-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE RUNNER_RATING (RUNNER_ID INT, RUNNER_RATING INT)

INSERT INTO RUNNER_RATING
VALUES(1, 4), (2,2), (3,5)

SELECT * FROM RUNNER_RATING
SELECT * FROM customer_orders
SELECT * FROM [dbo].[runner_orders]
--4). Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
		--customer_id
		--order_id
		--runner_id
		--rating
		--order_time
		--pickup_time
		--Time between order and pickup
		--Delivery duration
		--Average speed
		--Total number of pizzas

SELECT
	C.CUSTOMER_ID,
	C.ORDER_ID,
	RUN.RUNNER_RATING,
	C.ORDER_TIME, 
	R.PICKUP_TIME,
	C.ORDER_TIME - R.PICKUP_TIME AS COOK_TIME,
	R.DURATION, 
	--AVG(SPEED)
	COUNT(C.ORDER_ID) AS TOTAL_PIZZAS
FROM customer_orders C
JOIN runner_orders R ON
	C.ORDER_ID = R.ORDER_ID
JOIN RUNNER_RATING RUN ON 
	R.RUNNER_ID = RUN.RUNNER_ID
WHERE CANCELLATION IS NOT NULL 
AND CANCELLATION NOT IN ('Resturant Cancellation', 'Customer Cancellation')
GROUP BY C.CUSTOMER_ID,
		C.ORDER_ID,
		RUN.RUNNER_RATING,
		C.ORDER_TIME, 
		R.PICKUP_TIME,
		R.DURATION



--5). If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?