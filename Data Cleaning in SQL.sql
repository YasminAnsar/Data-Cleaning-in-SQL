/*
                        Cleaning Data in SQL Quries
*/
------------------------------------------------------------------
/*
---- #1
*/
--- Looking all the data in the table

Select * from [dbo].[Housing]

------------------------------------------------------------------
/*
---- #2
*/
--- Standardize Date Formate 

SELECT SaleDate FROM [dbo].[Housing]   -- checking for the sales date column

SELECT SaleDate, CONVERT(Date,SaleDate)   
FROM [dbo].[Housing]                       --Converting SaleDate to only date format 

ALTER TABLE [dbo].[Housing]
ADD SaleDateConverted Date;               ---Adding a new column to the housing table SaleDateConverted

UPDATE [dbo].[Housing] 
SET SaleDateConverted = CONVERT(Date,SaleDate)      --Updating the SaleDateConverted and setting it to Date only column

SELECT SaleDateConverted FROM [dbo].[Housing]       ---Checking the data again 

---- In the end will drop the SaleDate column

------------------------------------------------------------------
/*
---- #3
*/
----Populate property address data

SELECT propertyaddress from [dbo].[Housing]         -- Selecting property address column


SELECT count(*) from [dbo].[Housing] where PropertyAddress is null;  -- looking at the data where property address is null

---it shows there are 29 rows with null property address 
/*
To fill the null values in the propertyaddress column will use a self join. Self join will compare the row again it self and 
when it sees the null value it will replace it with the address that has the corressponding parcelID
*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM [dbo].[Housing] a
JOIN [dbo].[Housing] b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID] != b.[UniqueID]
WHERE a.[PropertyAddress] IS NULL;            --- it will show all the parcelID's that are duplicate and have missing addresses

---Will populate the propertyaddress from the existing one with same parcelID
 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [dbo].[Housing] a
JOIN [dbo].[Housing] b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID] != b.[UniqueID]
WHERE a.[PropertyAddress] IS NULL;     --- After running this it will show all 29 rows are update with the address

--let confirm this by running this query again
SELECT count(*) from [dbo].[Housing] where PropertyAddress is null;  -- looking at the data where property address is null

-- The result shows that now there are no data with missing propertyaddres

------------------------------------------------------------------
/*
---- #4
*/
----Breaking out propertyaddress coulmn into seprate column of (address, city)
SELECT PropertyAddress FROM [dbo].[Housing]

--In the address there are numbers, address text and comma that is seprating state so seprate this will use substring

SELECT SUBSTRING (PropertyAddress, 1, CHARINDEX(',' ,PropertyAddress)) AS Address
From  [dbo].[Housing]                     --- Now we got the stating number and address till the comma but I want to get rid of this comma so will use 

SELECT SUBSTRING (PropertyAddress, 1, CHARINDEX(',' ,PropertyAddress) -1) AS Address
,SUBSTRING (PropertyAddress, CHARINDEX(',' ,PropertyAddress) +1, LEN(PropertyAddress)) AS City
From  [dbo].[Housing]     ---As this CHARINDEX is just providing the position of the string letter so by doing -1 will select one step before deliminator ','

-- now creating new column for city and address to store these split address values

ALTER TABLE [dbo].[Housing]
ADD Address Varchar(255);               ---Adding a new column Address

UPDATE [dbo].[Housing] 
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' ,PropertyAddress) -1) --Updating the address column using substring 

ALTER TABLE [dbo].[Housing]
ADD City Varchar(255);              ---- Adding a new column City

UPDATE [dbo].[Housing] 
SET City = SUBSTRING (PropertyAddress, CHARINDEX(',' ,PropertyAddress) +1, LEN(PropertyAddress)) --Updating the new column city using substring method

--Checking how the table looks now after adding new columns
SELECT * FROM [dbo].[Housing]   --new columns of Address and City are added at the end of the table.

------------------------------------------------------------------
/*
---- #5
*/
----Breaking out owneraddress coulmn into seprate column of (address, city, state)

SELECT [OwnerAddress] FROM [dbo].[Housing]   -- Looking at the owner address

--Using Parse method to split this column into address, city and state 

SELECT
PARSENAME(REPLACE([OwnerAddress], ',', '.'),3) AS city
FROM [dbo].[Housing]           --using only parsename will not work because we have , not . so for that we replace ',' with '.'

--Now will create new colum for OwnerSplitAddress, OwnerCity, OwnerState

ALTER TABLE [dbo].[Housing]
ADD OwnerSplitAddress Varchar(255);

ALTER TABLE [dbo].[Housing]
ADD OwnerCity Varchar(255);

ALTER TABLE [dbo].[Housing]
ADD OwnerState Varchar(255);

---Updating all the column with the splitted data from the owner address column

UPDATE [dbo].[Housing] 
SET OwnerSplitAddress = PARSENAME(REPLACE([OwnerAddress], ',', '.'),3) 


UPDATE [dbo].[Housing] 
SET OwnerCity = PARSENAME(REPLACE([OwnerAddress], ',', '.'),2)


UPDATE [dbo].[Housing] 
SET OwnerState = PARSENAME(REPLACE([OwnerAddress], ',', '.'),1)

--Checking all the new columns are added with the splitted ownersaddress
SELECT * FROM [dbo].[Housing]     --It is all added now

------------------------------------------------------------------
/*
---- #6
*/
----Change Y and N to Yes and NO in 'Sold and vacant' field
--It shows there are for different types for yes and no. so will change them to Yes and No only

SELECT DISTINCT[SoldAsVacant] FROM [dbo].[Housing]   
GROUP BY [SoldAsVacant]

--Using Case statement to do this 

SELECT SoldAsVacant
, CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
      WHEN [SoldAsVacant] = 'N' THEN 'No'
	  ELSE [SoldAsVacant]
	  END
FROM [Portfolio_Project].[dbo].[Housing]
-- The above statement is working so now updating the [SoldAsVacant]  column 
UPDATE [dbo].[Housing]
SET [SoldAsVacant] = CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
      WHEN [SoldAsVacant] = 'N' THEN 'No'
	  ELSE [SoldAsVacant]
	  END

---checking the [SoldAsVacant] column to see how data looks now
SELECT DISTINCT[SoldAsVacant], COUNT([SoldAsVacant]) FROM [dbo].[Housing]   
GROUP BY [SoldAsVacant]          -- NOW [SoldAsVacant] column have only 'Yes' AND 'No'

------------------------------------------------------------------
/*
---- #7
*/
---- Removing duplicates

--In general it is not a good practice to remove all the duplicate because in that case we will lose orignal data
--But here I will remove duplicate data
--To check for duplicate first will USE the ROW_NUMBER() and then partition by (Window Function)the data to check how many duplicate exist

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER(
       PARTITION BY [ParcelID],
					[SaleDate],
					[SalePrice],
					[PropertyAddress],        --CTE will create wor numbers order by uniqueID
					[LegalReference]
		            ORDER BY 
                    [UniqueID]) Row_Num
FROM [dbo].[Housing] 
)
SELECT * FROM RowNumCTE                     --This CTE select statement will show all the rows where row number is greater than 1
WHERE  Row_Num > 1                
ORDER BY PropertyAddress

-- now we know we have 104 duplicate rows lets delete them
-- Uisng hte smae CTE and just using delete instead of slect

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER(
       PARTITION BY [ParcelID],
					[SaleDate],
					[SalePrice],
					[PropertyAddress],        --CTE will create row numbers order by uniqueID
					[LegalReference]
		            ORDER BY 
                    [UniqueID]) Row_Num
FROM [dbo].[Housing] 
)
DELETE FROM RowNumCTE                     --This CTE DELETE statement will REMOVE all the rows where row number is greater than 1
WHERE  Row_Num > 1                

--Checking the data again now all the duplicate are removed

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER(
       PARTITION BY [ParcelID],
					[SaleDate],
					[SalePrice],
					[PropertyAddress],        --CTE will create wor numbers order by uniqueID
					[LegalReference]
		            ORDER BY 
                    [UniqueID]) Row_Num
FROM [dbo].[Housing] 
)
SELECT * FROM RowNumCTE                     --This CTE select statement will show all the rows where row number is greater than 1
WHERE  Row_Num > 1                
ORDER BY PropertyAddress


------------------------------------------------------------------
/*
---- #8
*/
---- Removing Unused Columns
--As I have now splitted PropertyAddress and OwnerAddress so lets remove that coulmns from the data 
-- In real life project data before droping anycolumn ask for legal advice...

ALTER TABLE [dbo].[Housing]
DROP COLUMN [PropertyAddress], [OwnerAddress]

-- removing SaleDate column

ALTER TABLE [dbo].[Housing]
DROP COLUMN [SaleDate]

--checking if these columns are gone 

SELECT * FROM [dbo].[Housing]

-- Both columns are successfully removed.

---------------------------- Cleaned Data File----------------------------------------------------