
-- DATEBASE INFO
SELECT
        COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE
    FROM
        INFORMATION_SCHEMA.COLUMNS
    WHERE
        TABLE_NAME = 'ecom'
		 ORDER BY 2

-- Convert Customer_Since Column To Date For Better Usage
UPDATE ecom 
	SET Customer_Since = CONCAT(Customer_Since,'-1') 
FROM ecom;

ALTER TABLE ecom 
	ALTER COLUMN Customer_Since DATE;

-- Rename categoty_name_1 Table to CatName
EXEC sp_rename 'ecom.category_name_1', 'CatName';

-- Delete Un-Wanted Values From The Columns 
DELETE FROM ecom
WHERE status = '\N' OR status IS NULL;

DELETE FROM ecom
WHERE CatName = '\N' OR CatName IS NULL;

DELETE FROM ecom
WHERE Customer_Since = '#N/A' OR Customer_Since IS NULL;

DELETE FROM ecom
WHERE Customer_ID = '#N/A' OR Customer_ID IS NULL;

-- Drop Un-Wanted Table
ALTER TABLE ecom
	DROP COLUMN 
		sku, increment_id, sales_commission_code, M_Y,
		Working_Date, BI_Status, MV, Year, Month, FY
		;

-- Correct Prices Calcolation
UPDATE ecom SET grand_total =
	CASE 
		WHEN (price * qty_ordered) - discount_amount < 0
		THEN  price * qty_ordered
		ELSE (price * qty_ordered) - discount_amount
	END;

UPDATE ecom SET discount_amount =
	CASE 
		WHEN (price * qty_ordered) - discount_amount < 0
		THEN  0
		ELSE discount_amount
	END;

-- Check and Delete Duplicated
WITH CTE AS (
SELECT 
	* ,
	ROW_NUMBER() 
		OVER ( PARTITION BY 
							Customer_ID, status, created_at,
							grand_total, payment_method, price
						ORDER BY Customer_ID
						) Rnk
FROM ecom
)

DELETE FROM CTE 
WHERE Rnk > 1

-- Create the new table contain THE FINAL CLEANED DATA
CREATE TABLE CleanData  (
    item_id int,
    status nvarchar(50),
    created_at date,
    price float,
    qty_ordered int,
    grand_total float,
    CatName nvarchar(50),
    discount_amount float,
    payment_method nvarchar(50),
    Customer_Since varchar(50),
    Customer_ID int
);

-- Insert data into the new table from the existing table
INSERT INTO CleanData 
	(item_id, status, created_at, price,
	qty_ordered, grand_total, CatName,
	discount_amount, payment_method,
	Customer_Since, Customer_ID
	)SELECT 
		item_id, status, created_at,
		price, qty_ordered, grand_total,
		CatName, discount_amount, payment_method,
		Customer_Since, Customer_ID
	FROM ecom WHERE status = 'complete';

