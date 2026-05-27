CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN	
	BEGIN TRY
		PRINT '==================================================================================================================================================================='
		PRINT 'LOADING SILVER LAYER'
		PRINT '==================================================================================================================================================================='

		PRINT'===================================================================================================================================================================='
		PRINT'LOADING CRM TABLES'
		PRINT'===================================================================================================================================================================='

		DECLARE @start_time DATETIME, @end_time DATETIME ,@batch_start_time DATETIME ,@batch_end_time DATETIME

		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		/*
		***************************************************************************************************************************************************************************
		LOADING INTO CRM_CUST_INFO TABLE
		***************************************************************************************************************************************************************************
		*/
		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT'>> Inserting table: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date) 
		select 
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		from
			(
				select 
				cst_id,
				cst_key,
				TRIM(cst_firstname) AS cst_firstname,
				TRIM(cst_lastname) AS cst_lastname,
				CASE TRIM(UPPER(cst_marital_status))
					WHEN 'M' THEN 'Married'
					WHEN 'S' THEN 'Single'
				ELSE
					'n/a'
				END as cst_marital_status, --Normalize marital status values to readable format
				CASE TRIM(UPPER(cst_gndr))
					WHEN 'M' THEN 'Male'
					WHEN 'F' THEN 'Female'
				ELSE
					'n/a'
				END as cst_gndr, --Normalize gender values to readable format
				cst_create_date,
				ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) recent_flag 
				from bronze.crm_cust_info
			) t 
		WHERE recent_flag = 1  AND cst_id IS NOT NULL -- select most recent customer record with no null customer id
		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.crm_cust_info: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'*********************************************************************************************************************************************************************'
		/*
		***************************************************************************************************************************************************************************
		LOADING INTO CRM_PRD_INFO TABLE
		***************************************************************************************************************************************************************************
		*/
		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;

		SET @start_time = GETDATE();
		PRINT'>> Inserting table: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
		select 
			prd_id,
			REPLACE(LEFT(prd_key,5),'-','_') AS cat_id, --Replace keyword is used to replace - with _ inorder to match data from PX_CAT_G1V2 table. LEFT keyword is used instead of SUBSTRING to improve performance
			RIGHT(prd_key,LEN(prd_key)-6) AS prd_key,
			TRIM(prd_nm) AS prd_nm,
			COALESCE(prd_cost,0) AS prd_cst, -- Handles NULL values with 0
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'R' THEN 'Road'
				WHEN 'T' THEN 'Tour'
				ELSE 'n/a'
			END AS prd_line	, --Normally we ask the SME's to get know the abbreviation of the prd_line to give better cardiniality to the column and to make it more user friendly
			prd_start_dt,
			/*
			Removed prd_end_dt and instead we have used the lead function to get the starting date for the next pricing condition for the same product and have 
			determined the current end date by subtracting the next start date by 1 using dateadd key word
			*/
			DATEADD(DAY,-1,lead(prd_start_dt) OVER (partition by prd_key order by prd_start_dt ASC)) AS prd_end_dt 
		from bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.crm_prd_info: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'*********************************************************************************************************************************************************************'
		/*
		***************************************************************************************************************************************************************************
		LOADING INTO CRM_SALES_DETAILS
		***************************************************************************************************************************************************************************
		*/
		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT'>> Inserting table: silver.crm_sales_details';
		SET @start_time = GETDATE();
		INSERT INTO silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
		select 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			/*
			Correcting sls_sales values in cases when
			1. sls_sales is null
			2. sls_sales <=0
			3. sls_sales != sls_quantity * sls_price

			In all the above cases sls_sales is calculated by multiplying sls_quantity * sls_price
			*/
			CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
				 THEN sls_quantity * ABS(NULLIF(sls_price,0)) 
				 ELSE sls_sales
				 END as sls_sales,
			sls_quantity,
		-- Negative and NULL sls_sales values are cleansed with correct values 
			CASE WHEN sls_price <= 0 OR sls_price IS NULL
				THEN sls_sales/NULLIF(sls_quantity,0) --We convert sls_qty that is zero to null inorder to not have division by zero error
				ELSE sls_price
				END as sls_price
		from bronze.crm_sales_details

		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.crm_sales_details: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
		PRINT' '
		
		PRINT'===================================================================================================================================================================='
		PRINT'LOADING ERP TABLES'
		PRINT'===================================================================================================================================================================='
		
		
		/*
		***************************************************************************************************************************************************************************
		LOADING INTO ERP_CST_AZ12
		***************************************************************************************************************************************************************************
		*/

		/*

		TASKS:
		Upon inspection,
		1. We see that CUST_AZ12 customer id has few extra characters like NAS% that can be omitted inorder to better join crm_cust_info
		2. Birthdates that are below 1926 as we arent looking at customers above 100 years of age and bdate > current date i.e 08.05.2026
		3. Gender column to be NULL

		*/

		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.erp_CUST_AZ12';
		TRUNCATE TABLE silver.erp_CUST_AZ12;

		PRINT'>> Inserting table: silver.erp_CUST_AZ12';
		SET @start_time = GETDATE();
		INSERT INTO silver.erp_CUST_AZ12(CID,BDATE,GEN)
		Select 
		CASE WHEN TRIM(CID) LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID)) 
			 ELSE TRIM(CID)
			 END as cst_id,
		-- CONVERTING ALL THE BDATE ABOVE CURRENT DATE TO BE NULL
		CASE WHEN BDATE>GETDATE() THEN NULL
			 ELSE BDATE
			 END AS BDATE,
		CASE WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
			 WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'	
			 ELSE 'n/a'
			 END AS GEN
		from bronze.erp_CUST_AZ12

		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.erp_CUST_AZ12: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'*********************************************************************************************************************************************************************'

		/*
		***************************************************************************************************************************************************************************
		LOADING INTO ERP_LOC_A101
		***************************************************************************************************************************************************************************
		*/

		/*
		UPON OBSERVATION
		1. REMOVE HYPHEN IN CID WITH BLANK INORDER TO BE THE SAME WITH CUST_KEY 
		2. WE SEE DISCREPANCIES IN COUNTRY COLUMN WITH DIFFERENT NAMES AND ABBREVIATION FOR THE SAME COUNTRY I.E DE AND GERMANY
		*/

		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.erp_LOC_A101';
		TRUNCATE TABLE silver.erp_LOC_A101;

		PRINT'>> Inserting table: silver.erp_LOC_A101';
		SET @start_time = GETDATE();
		INSERT INTO silver.erp_LOC_A101(CID,cntry)
		SELECT 
			REPLACE(CID,'-',''),
			CASE 
				WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				WHEN TRIM(CNTRY) IN ('US','USA') THEN 'United States'
				WHEN TRIM(CNTRY) = '' OR TRIM(CNTRY) IS NULL THEN 'n/a'
				ELSE TRIM(CNTRY)
			END AS CNTRY
		FROM bronze.erp_LOC_A101

		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.erp_LOC_A101: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'*********************************************************************************************************************************************************************'
	
		/*
		***************************************************************************************************************************************************************************
		LOADING INTO ERP_PX_CAT_G1V2
		***************************************************************************************************************************************************************************
		*/

		--THE ERP_PX_CAT_G1V2 COLUMNS LOOKS GOOD POST INITIAL EXAMNINATION THEREFORE CAN BE DIRECTLY LOADED INTO SILVER LAYER

		--Truncating contents if there are any in the table
		PRINT'>> Truncating table: silver.erp_PX_CAT_G1V2';
		TRUNCATE TABLE silver.erp_PX_CAT_G1V2;

		PRINT'>> Inserting table: silver.erp_PX_CAT_G1V2';
		SET @start_time = GETDATE();
		INSERT INTO silver.erp_PX_CAT_G1V2(ID,CAT,SUBCAT,MAINTENANCE)
		SELECT 
			ID,
			CAT,
			SUBCAT,
			MAINTENANCE
		FROM bronze.erp_PX_CAT_G1V2

		SET @end_time = GETDATE();
		PRINT '>> Execution time of silver.erp_PX_CAT_G1V2: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT' '
		PRINT'====================================================================================================================================================================='

		SET @batch_end_time = GETDATE();
		PRINT'SILVER LAYER LOADING COMPLETED'
		PRINT'              -TOTAL BATCH EXECUTION TIME: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) +' sec'
		PRINT'====================================================================================================================================================================='

	END TRY
	BEGIN CATCH
		PRINT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
		PRINT 'ERROR MESSAGE:' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE:' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	END CATCH
END
