/*

Data Cleaning with SQL Server

*/

SELECT *
FROM Portfolio_Projects.dbo.Nashville_Housing;

--Standarizing the date, from datetime to only date
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Portfolio_Projects.dbo.Nashville_Housing;

ALTER TABLE Portfolio_Projects.dbo.Nashville_Housing ALTER COLUMN SaleDate Date;

SELECT SaleDate
FROM Portfolio_Projects.dbo.Nashville_Housing;

-- Filling up the PropertyAddress column, using the ParcelID and the UniqueID as reference points

SELECT *
FROM Portfolio_Projects.dbo.Nashville_Housing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID /* We can see if there are properties with the same address */;


--Let's do a self join and see if we can populate properties with the same ParcelID and different UniqueID
SELECT t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress, ISNULL(t1.PropertyAddress, t2.PropertyAddress) 
FROM Portfolio_Projects.dbo.Nashville_Housing AS t1
JOIN Portfolio_Projects.dbo.Nashville_Housing AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL;

UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM Portfolio_Projects.dbo.Nashville_Housing AS t1
JOIN Portfolio_Projects.dbo.Nashville_Housing AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL;

--Breaking down the PropertyAddress column into individual columns of address and City

SELECT PropertyAddress
FROM Portfolio_Projects.dbo.Nashville_Housing;

--This query will give us the property address

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM Portfolio_Projects.dbo.Nashville_Housing


--Now let's find the city

SELECT
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM Portfolio_Projects.dbo.Nashville_Housing

--Create the city column

ALTER TABLE Portfolio_Projects.dbo.Nashville_Housing
ADD PropertyCity Varchar(50);

UPDATE Portfolio_Projects.dbo.Nashville_Housing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

SELECT PropertyCity
FROM Portfolio_Projects.dbo.Nashville_Housing;

--Alter the PropertyAddress column

UPDATE Portfolio_Projects.dbo.Nashville_Housing
SET PropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

SELECT PropertyAddress
FROM Portfolio_Projects.dbo.Nashville_Housing;

-- We do the same with the OwnerAddress, but this time we use PARSENAME instead of SUBSTRING

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS State
FROM Portfolio_Projects.dbo.Nashville_Housing;

--Let's create two columns, OwnerCity and OwnerState

ALTER TABLE Portfolio_Projects.dbo.Nashville_Housing
ADD OwnerCity Varchar(30);

UPDATE Portfolio_Projects.dbo.Nashville_Housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2);

SELECT OwnerCity
FROM Portfolio_Projects.dbo.Nashville_Housing;


ALTER TABLE Portfolio_Projects.dbo.Nashville_Housing
ADD OwnerState Varchar(5);

UPDATE Portfolio_Projects.dbo.Nashville_Housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);

SELECT OwnerState
FROM Portfolio_Projects.dbo.Nashville_Housing;

--Now let's alter the OwnerAddress column

UPDATE Portfolio_Projects.dbo.Nashville_Housing
SET OwnerAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

SELECT OwnerAddress
FROM Portfolio_Projects.dbo.Nashville_Housing;


-- Standarizing the SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio_Projects.dbo.Nashville_Housing
GROUP BY (SoldAsVacant)
ORDER BY 2 DESC;

-- We're going to assing "N" to "No" and "Y" to "Yes"

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
		 ELSE SoldAsVacant
		 END
FROM Portfolio_Projects.dbo.Nashville_Housing;

UPDATE Portfolio_Projects.dbo.Nashville_Housing
	SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
							WHEN SoldAsVacant = 'N' THEN 'NO'
							ELSE SoldAsVacant
							END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio_Projects.dbo.Nashville_Housing
GROUP BY (SoldAsVacant)
ORDER BY 2 DESC;



--Removing Duplicates that affects data quality
WITH RowNum AS (
SELECT *,
	   ROW_NUMBER() OVER(
	   PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID) AS row_num

FROM Portfolio_Projects.dbo.Nashville_Housing
)
SELECT *
FROM RowNum
WHERE row_num > 1
ORDER BY PropertyAddress;

-- There are a 104 rows that have the same data that should be unique, except "UniqueID", let's delete them 

WITH RowNum AS (
SELECT *,
	   ROW_NUMBER() OVER(
	   PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID) AS row_num

FROM Portfolio_Projects.dbo.Nashville_Housing
)
DELETE
FROM RowNum
WHERE row_num > 1
;

SELECT *
FROM Portfolio_Projects.dbo.Nashville_Housing;