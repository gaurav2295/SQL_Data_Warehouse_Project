/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse_GVB' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse_GVB' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- Select the master datasource
USE master;
GO

-- Drop and recreate the 'Datawarehouse_GVB' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Datawarehouse_GVB')
BEGIN
  ALTER DATABASE Datawarehouse_GVB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE Datawarehouse;
END;
GO


-- Create the 'Datawarehouse_GVB' database

CREATE DATABASE Datawarehouse_GVB;

USE Datawarehouse_GVB;

-- Create schemas for each layer i.e bronze, silver and gold

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
