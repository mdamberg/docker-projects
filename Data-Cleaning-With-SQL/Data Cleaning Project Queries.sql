-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
																					/*	Cleaning Data in SQL  */
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE [DataCleaningProject]
GO


Select *
FROM [dbo].[NashvilleHousing]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Change Date Format

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Here we are converting from a Date/Time format to a Date format.  

Select [SaleDateConverted], CONVERT(DATE,[SaleDate])
FROM [dbo].[NashvilleHousing]

UPDATE [dbo].[NashvilleHousing]
SET SaleDate = CONVERT(DATE,[SaleDate])

--Creating a new column for the Date column by altering table and then updating database. 

ALTER TABLE	[dbo].[NashvilleHousing]
ADD SaleDateConverted Date

UPDATE [dbo].[NashvilleHousing]
SET SaleDateConverted = CONVERT(DATE,[SaleDate])


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Populate Property Adderess Data

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Below we can see that some of the Property Addresses have NULL values. 

SELECT *
FROM [dbo].[NashvilleHousing]
WHERE [PropertyAddress] IS NULL
ORDER BY [ParcelID]

--Upon further research, these NULL Property Addresses have matching ParcelID's and Property Addresses with another row.

--This self join below shows that the Property Addresses' Parcel ID's  match and therefore should have the same address populate.

SELECT a.[ParcelID], a.[PropertyAddress], b.[ParcelID], b.[PropertyAddress]
FROM [dbo].[NashvilleHousing] a
JOIN [dbo].[NashvilleHousing] b
	ON a.[ParcelID] = b.[ParcelID]
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.[PropertyAddress] IS NULL


/*If one row has a ParcelID with an address and that same ParcelID appears in another row but with a NULL value for address, 
then we need to populate the NULL Address field with the listed address as demonstrated below with ISNULL. */ 

--Use ISNULL to populate the NULL addresses in a.PropertyAddress.

SELECT a.[ParcelID], a.[PropertyAddress], b.[ParcelID], b.[PropertyAddress], ISNULL(a.[PropertyAddress], b.[PropertyAddress])
FROM [dbo].[NashvilleHousing] a
JOIN [dbo].[NashvilleHousing] b
	ON a.[ParcelID] = b.[ParcelID]
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.[PropertyAddress] IS NULL

--UPDATE Table to add addresses into table.

UPDATE a
SET [PropertyAddress] = ISNULL(a.[PropertyAddress], b.[PropertyAddress])
FROM [dbo].[NashvilleHousing] a
JOIN [dbo].[NashvilleHousing] b
	ON a.[ParcelID] = b.[ParcelID]
	AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.[PropertyAddress] IS NULL

--Running the above Select statment with the inital ISNULL reveals there are no more NULL Values.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Seperating Out PropertyAddress Column Into Individual Columns (Address, City, State) using Substring and CHARINDEX.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT [PropertyAddress]
FROM [dbo].[NashvilleHousing]

--Remove   using SubString

SELECT
SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress])) AS Address
FROM [dbo].[NashvilleHousing]

--Comma is still present so we use a -1 value in the CHARINDEX.

SELECT
SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress])-1) AS Address
FROM [dbo].[NashvilleHousing]

--Seperating City out of Address by adding additional CHARINDEX statement.

SELECT
SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress])-1) AS Address,	--Selects just the address from string.
SUBSTRING([PropertyAddress], CHARINDEX(',', [PropertyAddress])+1, LEN([PropertyAddress])) 
AS Address	--Starts at the CHARINDEX runs length of PropertyAddress selects just the city from the string.

FROM [dbo].[NashvilleHousing]																			

--Using UPDATE to add new Columns for the seperated parts of the address; Address and City.

ALTER TABLE	[dbo].[NashvilleHousing]
ADD PropertySplitAddress NVARCHAR(255)	--Splits the Address 

UPDATE [dbo].[NashvilleHousing]
SET PropertySplitAddress = SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress])-1)


ALTER TABLE	[dbo].[NashvilleHousing]
ADD PropertySplitCity NVARCHAR(255)	--Splits the City

UPDATE [dbo].[NashvilleHousing]
SET PropertySplitCity = SUBSTRING([PropertyAddress], CHARINDEX(',', [PropertyAddress])+1, LEN([PropertyAddress]))

--Check our work. Running the query we can see we have seperated the Address and City making it look much simpler and cleaner.

Select [PropertySplitAddress], [PropertySplitCity] from [dbo].[NashvilleHousing]	

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Splitting up OwnerAddress Column into Address, City and State using PARSENAME.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT [OwnerAddress]		
FROM [dbo].[NashvilleHousing]

--Replacing periods with commas --> using PARSENAME to PARSE out Address, City and State into seperate Columns. 

SELECT
PARSENAME(REPLACE([OwnerAddress],',', '.') , 3) AS Address
, PARSENAME(REPLACE([OwnerAddress],',', '.') , 2) AS City
, PARSENAME(REPLACE([OwnerAddress],',', '.') , 1) AS State
FROM [dbo].[NashvilleHousing]

--Adding seperate columns to our table. 

ALTER TABLE	[dbo].[NashvilleHousing]
ADD OwnerSplitAddress NVARCHAR(255)

	UPDATE [dbo].[NashvilleHousing]	
SET OwnerSplitAddress = PARSENAME(REPLACE([OwnerAddress],',', '.') , 3)	--Adding the Address

ALTER TABLE	[dbo].[NashvilleHousing]
ADD OwnerSplitCity NVARCHAR(255)

	UPDATE [dbo].[NashvilleHousing]
SET OwnerSplitCity = PARSENAME(REPLACE([OwnerAddress],',', '.') , 2)	--Adding the City


ALTER TABLE	[dbo].[NashvilleHousing]
ADD OwnerSplitState NVARCHAR(255)

	UPDATE [dbo].[NashvilleHousing]
SET OwnerSplitState = PARSENAME(REPLACE([OwnerAddress],',', '.') , 1)	--Adding the State

--Lets check our work by exectuting the query below.

SELECT *
FROM [dbo].[NashvilleHousing]		

--We have now seperated our original OwnerAddress column into an Address, State and City column making it much easier to work with and read. 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --Change Y and N to Yes and No in "Sold as Vacant" Field
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--There are inconsistent values in this field = Y, Yes, N and No. 

--Standardize this to Yes and No using a CASE Statement.

Select Distinct [SoldAsVacant]
	, Count([SoldAsVacant])
FROM [dbo].[NashvilleHousing]	
GROUP BY [SoldAsVacant]
ORDER BY 2

-- when any 'Y' or 'N' values are found they are changed to 'Yes' and 'No' 
-- if the value meets neither of those critera it remains SoldAsVacant and is already in 'Yes' or 'No' format. 

SELECT 
	[SoldAsVacant],
	CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
		 WHEN [SoldAsVacant] = 'N' THEN 'No'
		 ELSE [SoldAsVacant] 
		 END 
FROM [dbo].[NashvilleHousing]

--Now we will update this CASE statement into our table

UPDATE [dbo].[NashvilleHousing]
SET [SoldAsVacant] = CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
						  WHEN [SoldAsVacant] = 'N' THEN 'No'
					   	  ELSE [SoldAsVacant] 
						  END

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- check this data for duplicates.
--We need a way to Id these duplicate rows, to do this we will be using RowNumber 

WITH RowNumCTE AS (
SELECT * , 
	ROW_NUMBER () OVER(
	PARTITION BY [ParcelID], 
				 [PropertyAddress],
				 [SalePrice],
				 [SalePrice],
				 [LegalReference]
	ORDER BY [UniqueID ]
	) AS row_num
FROM [dbo].[NashvilleHousing]
)

Select *		
FROM RowNumCTE
WHERE row_num >1		

--The duplictes which are identified in the above query will be assigned a row number of 2. 


WITH RowNumCTE AS (
SELECT * , 
	ROW_NUMBER () OVER(
	PARTITION BY [ParcelID], 
				 [PropertyAddress],
				 [SalePrice],
				 [SalePrice],
				 [LegalReference]
	ORDER BY [UniqueID ]
	) AS row_num
FROM [dbo].[NashvilleHousing]

DELETE		
FROM RowNumCTE
WHERE row_num >1

--A total of 104 rows were determined to be duplicates and were deleted. 


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete  columns which are hard to work ie the  original address columns we split earlier. 

ALTER TABLE [dbo].[NashvilleHousing]
	DROP COLUMN [OwnerAddress], 
				[TaxDistrict], 
				[PropertyAddress]

ALTER TABLE [dbo].[NashvilleHousing]
	DROP COLUMN SaleDate

--After a quick select all we can see the columns have successfully been removed.  
