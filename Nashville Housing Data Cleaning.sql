/*

Let's clean data in SQL queries

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing



-- Standardize Date Format

SELECT	SaleDateConverted, 
		CONVERT(Date, SaleDate) AS compare_date
FROM PortfolioProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-------------------------------------------------------------------------------------------------------


-- Populate Property Address Data

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
-- WHERE PropertyAddress is null
ORDER BY ParcelID

-- Identical ParcelID's have the same Property Address, so we can use this information to populate null values for Property Address

SELECT	a.ParcelID, 
		a.PropertyAddress, 
		b.ParcelID, 
		b.PropertyAddress, 
		ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] != b.[UniqueID]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] != b.[UniqueID]
WHERE a.PropertyAddress is null

-------------------------------------------------------------------------------------------------------


-- Break out Address into Individual Columns (Street, City, State)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

-- Use SUBSTRING to separate the street name and city from the address column.
SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS street_address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) as City
FROM PortfolioProject.dbo.NashvilleHousing

-- Update table with street address
ALTER TABLE NashvilleHousing
ADD street_address Nvarchar(255); 

UPDATE NashvilleHousing
SET street_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

-- Update table with city
ALTER TABLE NashvilleHousing
ADD city Nvarchar(255);

UPDATE NashvilleHousing
SET city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress));

-- Check to see that these new columns were added correctly
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-- Now let's look at owner addresses. We need to split these out as well, but we'll use PARSENAME() (good for delimited values)
--instead of SUBSTRING. But PARSENAME() looks for periods instead of commas. Need to use REPLACE() to take care of this.

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
	PARSENAME(REPLACE(Owneraddress, ',', '.'), 3) AS owner_street,
	PARSENAME(REPLACE(Owneraddress, ',', '.'), 2) AS owner_city,
	PARSENAME(REPLACE(Owneraddress, ',', '.'), 1) AS owner_state
FROM PortfolioProject.dbo.NashvilleHousing

-- Add owner street, city, and state addresses columns to table
ALTER TABLE NashvilleHousing
ADD owner_street Nvarchar(255),
	owner_city Nvarchar(255),
	owner_state Nvarchar(255);

-- Update values in columns
UPDATE NashvilleHousing
SET owner_street = PARSENAME(REPLACE(Owneraddress, ',', '.'), 3),
	owner_city = PARSENAME(REPLACE(Owneraddress, ',', '.'), 2),
	owner_state = PARSENAME(REPLACE(Owneraddress, ',', '.'), 1);

-------------------------------------------------------------------------------------------------------


-- Change Y to N to Yes and No in "Sold as Vacant" Field

SELECT	DISTINCT(SoldAsVacant),
		COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- We see that 'Yes' and 'No' have a lot more counts than 'Y' and 'N', so we will convert everything to yes and no.

SELECT	SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant
			 END
FROM PortfolioProject.dbo.NashvilleHousing

-- Update our table with our CASE WHEN statement. 
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-------------------------------------------------------------------------------------------------------


-- Remove Duplicates

WITH row_num_cte AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY 
						UniqueID
						) row_num
FROM PortfolioProject.dbo.NashvilleHousing 
--ORDER BY ParcelID
)
SELECT *
FROM row_num_cte
WHERE row_num > 1


-- Now Delete the duplicates 
WITH row_num_cte AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY 
						UniqueID
						) row_num
FROM PortfolioProject.dbo.NashvilleHousing 
)
DELETE
FROM row_num_cte
WHERE row_num > 1

-------------------------------------------------------------------------------------------------------


-- Delete Unused Columns (Never to raw data)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress,
			TaxDistrict,
			PropertyAddress,
			SaleDate


