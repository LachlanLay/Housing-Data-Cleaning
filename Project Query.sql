
/*
Cleaning data with SQL queries
*/


---------------------------------------------------------------------------------------------------------------------------
-- Standardise Date format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

SELECT SaleDate
FROM PortfolioProject.dbo.PortfolioProject.dbo.NashvilleHousing

/* Another option is to create a new column called SaleDateCONVERTed */

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateCONVERTed Date; 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateCONVERTed = CONVERT(Date, SaleDate)


---------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data 

SELECT PropertyAddress 
FROM PortfolioProject.dbo.NashvilleHousing
WHERE isnull(PropertyADDress,'')=''

/* We observe NULL values in PropertyAddress */

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

/* If there are multiple parcels, fill out NULLs with prior PropertyAddress
   Create a table to show these values */

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID] 
WHERE a.PropertyAddress is null

/* Update the values */ 

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID] 
WHERE a.PropertyAddress is null


---------------------------------------------------------------------------------------------------------------------------
/* Separate Address */ 

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as 'Address'
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Suburb /* Find comma, jump ahead one value then increment for the length of Address */ 
FROM PortfolioProject.dbo.NashvilleHousing

/* Update table to reflect address change */

/* Create two new colums */

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

/* Split OwnerAddress using Parse Name, much easier method */ 

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3) 
,PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2) 
,PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1) 
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1) 


---------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


---------------------------------------------------------------------------------------------------------------------------
-- Remove duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)

DELETE   /* Best practice would be not to delete from raw database */ 
FROM RowNumCTE
WHERE row_num > 1


---------------------------------------------------------------------------------------------------------------------------
-- Remove unused columns
/* Best practice would be not to delete from raw database */ 

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate