/*
==============================================================================
========================================
-- Data quality Check of the Bronze Layer
========================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  standardization across the 'silver' schema. It includes checks for:
  - Null or duplicates primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.
  
Usage Notes:
  - Run these checks after data loading Silver Layer.
  - Investigate and resolve any discrepancies found during the checks.
==============================================================================
*/

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'crm_cust_info' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT 
* 
FROM 
bronze.crm_cust_info
------------------------------------------------------------
-- Checking for Nulls or duplicates in the primary key
SELECT
  cst_id,
  COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--------------------------------------
-- Checking for Unwanted spaces
SELECT
	cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)
--------------------------------------------
-- Checking for data standardization & Consistency

SELECT 
	DISTINCT cst_gndr
FROM bronze.crm_cust_info
-->>>>>>>>>>>>>>>>>>>>>>>>>
SELECT 
	DISTINCT cst_marital_status
FROM bronze.crm_cust_info

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'bronze.crm_prd_info' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- Checking for Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Checking for unwanted spaces in the prd_key columnn
-- Expectations: No Result
SELECT 
	prd_key,
	prd_nm,
	prd_cost -- Checking for costs less than 0 or with nulls
FROM bronze.crm_prd_info
WHERE prd_key != TRIM(prd_key) OR prd_nm != TRIM(prd_nm)
OR prd_cost < 0 OR prd_cost IS NULL

-- Checking for data standardization & Consistency
SELECT DISTINCT prd_line FROM bronze.crm_prd_info

-- Checking invalid Date Orders
-- Expectations: No Results
SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'bronze.crm_sales_details' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT TOP 100 * FROM bronze.crm_sales_details
-- Checking for unwanted spaces in the sls_ord_num and sls_prd_key columns
-- Expectations: No Result
SELECT 
	sls_ord_num,
	sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num) OR sls_prd_key != TRIM(sls_prd_key)

-- Checking for invalid dates in the sls_order_dt column (ensure to do same for each date column)
	-- Check for zeros and negative numbers
	-- Check for the length of the date to ensure it fits the 8-character standard date
	-- Check for outliers by validating the boundaries of the date range
	-- Check for invalid date orders (order dates must be smaller than shipping or due dates)
SELECT
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101
OR sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt
-- To clean up, make those cases nulls

/* - Checking for Data consistency in the sales, quatitiy and price columms
	- The following business rule must be met to ensure a clean data
		i. Sales must be equal to (Quantity * Price)
		ii. Sales, quantity and price should not contain negative values, zeros or nulls 
*/
SELECT DISTINCT 
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL  OR sls_price IS NULL
OR sls_sales <= 0  OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
/* - Rules to fix the data quality issues
		i. If Sales is negative, zero, or null, derive it using Quantity and Price.
		ii. If Price is zero or null, calculate it using Sales and Quantity.
		iii. If Price is negative, convert it to a positive value.
*/	

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'bronze.erp_cust_az12' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

/* - Check for connecting keys. Here the 'cid' is a connecting key 
to the 'cst_key' in the 'bronze.crm_cust_info' table
- Ensure the keys are matching
*/
SELECT
	cid
FROM bronze.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM bronze.crm_cust_info)

-- Checking for out-of-range-dates
SELECT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consitency for the 'gen' Column
SELECT DISTINCT gen FROM bronze.erp_cust_az12

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'bronze.erp_loc_a101' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
/* - Check for connecting keys. Here the 'cid' is a connecting key 
to the 'cst_key' in the 'bronze.crm_cust_info' table
- Ensure the keys are matching
*/

SELECT * FROM bronze.erp_loc_a101
WHERE cid NOT IN 
(SELECT cst_key FROM bronze.crm_cust_info)

-- Checking for all possible values in the cntry column
SELECT DISTINCT cntry 
FROM bronze.erp_loc_a101
ORDER BY cntry

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- DATA QUALITY CHECK FOR THE 'bronze.erp_px_cat_g1v2' Table
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
/* - Check for connecting keys. Here the 'cat_id' is a connecting key 
to the 'id' in the 'bronze.ero_px_cat_g1v2' table
- Ensure the keys are matching
*/

SELECT * FROM silver.crm_prd_info
WHERE cat_id NOT IN
(SELECT id FROM bronze.erp_px_cat_g1v2)
 
-- Checking for trailing spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE id != TRIM(id) OR cat != TRIM(cat) 
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance)

-- Checking for Data consitency and normilazation
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2


