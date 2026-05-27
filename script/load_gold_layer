/*
In gold layer we must follow the below best practices:
1. Ensure no duplicates are introduced due to the joins
2. Enable data integration for the columns that have data discrepancy between different tables
3. Use snake case naming conventions and give user friendly names for the columns (Data dictionary)
4. Create surrogate key if you dont want to use primary keys from the source system and they can be created by using Row_number window function or as a DDL statement at the time of table generation.
   The surrogate keys have suffix as key i.e <surrogate key name>_key
5. CREATE VIEW FOR THE GOLD LAYER
*/

CREATE OR ALTER VIEW [gold].[dim_customers] AS --DIMENSIONAL TABLE AS IT CONTAINS DESCRIPTIVE DATA
select
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE 
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the MAster for gender Info
		WHEN ci.cst_gndr = 'n/a' AND ca.gen IS NOT NULL AND ca.gen != 'n/a' THEN ca.gen
		ELSE COALESCE(ca.gen,'n/a')
	END AS gender, -- Integrated the gender data correctly by taking the most recent data from CRM if there are any data discrepancy between CRM and ERP data
	ci.cst_create_date AS create_date,
	ca.bdate AS birth_date,
	la.cntry AS country
from silver.crm_cust_info ci
left join silver.erp_CUST_AZ12 ca 
	on ci.cst_key = ca.cid
left join silver.erp_LOC_A101 la
	on ci.cst_key = la.cid

--*********************************************************************************************************************************************************************

/*
TO CHECK IF THERE ARE ANY DUPLICATES INTRODUCED DUE TO JOINING PROCESS
PRD_KEY,
COUNT(*)
*/

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY PRD_START_DT, PRD_KEY) AS product_key,
	p.prd_id AS product_id,
	p.prd_key AS product_number,
	p.prd_nm AS product_name,
	p.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	PC.maintenance,
	p.prd_cost AS cost,
	p.prd_line AS product_line,
	p.prd_start_dt AS product_start_date
FROM silver.crm_prd_info AS p
LEFT JOIN silver.erp_PX_CAT_G1V2 AS PC
	ON p.cat_id = PC.id
WHERE P.prd_end_dt IS NULL --SELECTING ONLY THOSE PRODUCTS THAT ARE CURRENTLY RELEVANT

/*
GROUP BY PRD_KEY
HAVING COUNT(*) > 1
*/

--*********************************************************************************************************************************************************************

/*
FACT TABLE OF SALES:
As this table contain information related to sales transactions.

-> Use dimensions surrogate key instead of ID's to easily connect facts with dimensions

In our scenario: We can use surrogate product key and customer key that we have generated for the dimensions table for products and customers
*/

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key AS product_key,
	cr.customer_key AS customer_id,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS ship_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cr
ON sd.sls_cust_id = cr.customer_id
