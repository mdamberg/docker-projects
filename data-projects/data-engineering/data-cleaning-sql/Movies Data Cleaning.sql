SELECT TOP (1000) [MOVIES]
      ,[YEAR]
      ,[GENRE]
      ,[RATING]
      ,[ONE-LINE]
      ,[STARS]
      ,[VOTES]
      ,[RunTime]
      ,[Gross]
  FROM [Movie Database].[dbo].[movies]

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
																			-- DATA CLEANING AND EXPLORATION 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------
		/* DELETING DUPLICATE DATA*/
------------------------------------------------

	/****************************/
	-- SEARCHING FOR DUPLICATES
	/****************************/

SELECT
		MOVIE_NAME,
		COUNT(*) AS NAME_COUNT		-- RETURNS COUNT OF DUPLICATE NAMES
	FROM MOVIES
	GROUP BY MOVIE_NAME
	HAVING COUNT(MOVIE_NAME) > 1

	/**********************************/
	-- RANKING DUPLICATES FOR REMOVAL 
	/**********************************/


SELECT
	MOVIE_NAME,
	ROW_NUMBER() OVER(PARTITION BY MOVIE_NAME ORDER BY MOVIE_NAME) AS MOVIE_RANK
FROM MOVIES

	/*******************************/
	-- DELETE DUPLICATES USING CTE 
	/*******************************/
	
WITH DUPLICATES AS 
	(
	SELECT
		MOVIE_NAME,
		ROW_NUMBER() OVER(PARTITION BY MOVIE_NAME ORDER BY MOVIE_NAME) AS MOVIE_RANK
	FROM MOVIES
	)

		DELETE				-- WE THEN JUST ADD A DELETE STATEMENT INSTEAD OF SELECT AND THIS WILL REMOVE THE DUPLICATES
		FROM DUPLICATES
			WHERE MOVIE_RANK > 1


	/****************/
	--GROSS COLUMN
	/****************/

 SELECT COUNT(MOVIE_NAME) GROSS_NULLS
 FROM MOVIES
 WHERE GROSS IS NULL

 SELECT
	COUNT(GROSS)
 FROM MOVIES
 WHERE GROSS IS NOT NULL

	/*************************************************/
	--460 ROWS ARE NULL IN GROSS COLUMN OUT OF 9999
	/*************************************************/

 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --YEAR COLUMN
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
	SUBSTRING(YEAR, 1,1)
FROM MOVIES
WHERE YEAR IS NOT NULL

	--test query for cleaning the year column
SELECT
    MOVIE_NAME, 
    REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(YEAR)), '(', ''), ')', ''), '–', ''), '-', '') AS CleanedYear		-- REMOVES (,), AND OTHER CHARACTERS FROM YEAR COLUMN
FROM
    MOVIES;

	--updating table with cleaned year column
UPDATE MOVIES
SET YEAR = REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(YEAR)), '(', ''), ')', ''), '–', ''), '-', '');


--------------------------------------------------------------------------------------------
--STILL NEED TO SEPARATE OUT DATES THAT ARE RANGES IN YEARS COLUMN (20132022 --> (2013-2022)
--------------------------------------------------------------------------------------------

	--TEST QUERY
	SELECT
		CASE
			WHEN LEN(YEAR) = 8 THEN CONCAT(substring(year, 1, 4), '-', substring(year, 5, 4))
			ELSE YEAR END
	FROM MOVIES


UPDATE MOVIES
SET YEAR = CASE
			WHEN LEN(YEAR) = 8 THEN CONCAT(substring(year, 1, 4), '-', substring(year, 5, 4))
			ELSE YEAR END
	FROM MOVIES


	SELECT * FROM MOVIES

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GENRE COLUMN
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--SOME OF THE VALUES THAT ARE WHOLE NUMBERS ARE NOT DISPLAYING .0 AFTER THEM


