/*
=====================================================================================
Script to Create Or Alter Stored Procedure for ERP Tables
=====================================================================================
Script Purpose:
This script creates or alters the stored procedure to be executed for loading records
into bronze layer into erp tables. This stored procedere explains how to handle errors 
during loading and helps in logging important faces of loading via log information.

*/


CREATE OR ALTER PROCEDURE bronze.LOAD_BRONZE AS
BEGIN
	BEGIN TRY
-- DECLARATION OF VARIABLES START AND END TIME TO CALCULATE TIME
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_time_total_load DATETIME, @end_time_total_load DATETIME
	SET @start_time_total_load = GETDATE();
		PRINT '***************************************';
		PRINT 'LOADING BRONZE LAYER: ERP TABLES';
		PRINT '***************************************';
		--TRUNCATING THE BRONZE.ERP_CUST_AZ12 TABLE
		
		PRINT '>>TRUNCATING TABLE: BRONZE.ERP_CUST_AZ12';
		-- START TIME FOR LOADING INTO BRONZE.ERP_CUST_AZ12 TABLE
		SET @start_time = GETDATE();
		TRUNCATE TABLE BRONZE.ERP_CUST_AZ12

		--INSERTING ALL RECORDS IN .CSV FILE IN A SINGLE SHOT
		PRINT '>>INSERTING TABLE: BRONZE.ERP_CUST_AZ12';
		BULK INSERT BRONZE.ERP_CUST_AZ12
		FROM 'D:\GVB\CUST_AZ12.csv'
		WITH
			(
				FIRSTROW =2,
				FIELDTERMINATOR =',',
				-- TABLOCK HELPS US TO INCREASE THE PERFORMANCE OF BULK INSERT BY LOCKING THE WHOLE TABLE AND IT PREVENTS OTHER USERS FROM WORKING ON THE TABLE
				TABLOCK
			)
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION FOR BRONZE.ERP_CUST_AZ12: '+CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'


		--TRUNCATING THE BRONZE.ERP_LOC_A101 TABLE
		PRINT '*******************************************************'
		PRINT '>>TRUNCATING TABLE: BRONZE.ERP_LOC_A101';
		SET @start_time = GETDATE();
		TRUNCATE TABLE BRONZE.ERP_LOC_A101

		--INSERTING ALL RECORDS IN .CSV FILE IN A SINGLE SHOT
		PRINT '>>INSERTING TABLE: BRONZE.ERP_LOC_A101';
		BULK INSERT BRONZE.ERP_LOC_A101
		FROM 'D:\GVB\LOC_A101.csv'
		WITH
			(
				FIRSTROW =2,
				FIELDTERMINATOR =',',
				-- TABLOCK HELPS US TO INCREASE THE PERFORMANCE OF BULK INSERT BY LOCKING THE WHOLE TABLE AND IT PREVENTS OTHER USERS FROM WORKING ON THE TABLE
				TABLOCK
			)

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION FOR BRONZE.ERP_LOC_A101: '+CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'


		--TRUNCATING THE BRONZE.ERP_PX_CAT_G1V2 TABLE
		PRINT '*******************************************************'
		PRINT '>>TRUNCATING TABLE: BRONZE.ERP_PX_CAT_G1V2';
		SET @start_time = GETDATE();
		TRUNCATE TABLE BRONZE.ERP_PX_CAT_G1V2

		--INSERTING ALL RECORDS IN .CSV FILE IN A SINGLE SHOT
		PRINT '>>INSERTING TABLE: BRONZE.ERP_PX_CAT_G1V2';
		BULK INSERT BRONZE.ERP_PX_CAT_G1V2
		FROM 'D:\GVB\PX_CAT_G1V2.csv'
		WITH
			(
				FIRSTROW =2,
				FIELDTERMINATOR =',',
				-- TABLOCK HELPS US TO INCREASE THE PERFORMANCE OF BULK INSERT BY LOCKING THE WHOLE TABLE AND IT PREVENTS OTHER USERS FROM WORKING ON THE TABLE
				TABLOCK
			)
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION FOR BRONZE.ERP_PX_CAT_G1V2: '+CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec'
		PRINT '*******************************************************'
		SET @end_time_total_load = GETDATE();
		PRINT '>> LOADING BRONZE LAYER COMPLETED!!!!!'
		PRINT ' '
		PRINT '>> TOTAL LOAD DURATION FOR ERP TABLES: ' + CAST(DATEDIFF(SECOND,@start_time_total_load,@end_time_total_load) AS NVARCHAR) +' sec'
  END TRY
  
	BEGIN CATCH
		PRINT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
		PRINT 'ERROR MESSAGE:' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE:' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	END CATCH
END
