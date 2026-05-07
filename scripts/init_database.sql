/* 
======================================================
Create Database and Schemas
======================================================
Script Purpose:
	This script creates a new database named 'DataWarehouse' after checking if already exists.
	If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
	within the database: 'bronze', 'silver', and 'gold'.
Warning:
	Running this script will drop the entire 'DataWarehouse' Database if it exists.
	All data in the database will be permanently deleted. Proceed with caution and
	ensure you have proper backups before running this script.
*/

-- Drop and recreate the 'DataWarehouse' database
USE Master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	DROP DATABASE DataWarehouse;
END

-- Creating the 'DataWarehouse' Database
CREATE  DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
