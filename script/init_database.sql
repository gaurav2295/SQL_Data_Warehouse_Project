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
