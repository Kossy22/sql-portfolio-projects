/* 
=================================================================
Customer Report
=================================================================
Purpose:
	- This report consolidates key customer metrics and behaviours

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculate valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
=================================================================
*/
CREATE VIEW gold.report_customers AS 
WITH cte_base_query AS(
/* ------------------------------------------------------------
1) Base Query: Retrieves core columns from Tables
   ------------------------------------------------------------
*/
SELECT 
	f.order_number,
	p.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	DATEDIFF(YEAR,c.birthdate,GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
),

cte_customer_aggregation AS(
/* ------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
   -------------------------------------------------------------------
*/

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MAX(order_date), GETDATE()) recency,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM cte_base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
	
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 29 THEN '20-29'
		WHEN age BETWEEN 30 AND 39 THEN '30-39'
		WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and above'
	END AS age_group,
	CASE 
		WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
		WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'Regular'
		ELSE 'New'
	END customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	recency,
	lifespan,
	-- Compute average order value (AVO)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders
	END AS avg_order_value,
	-- compute average monthly spent
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan
	END AS avg_monthly_spent
FROM cte_customer_aggregation

SELECT * FROM gold.report_customers

/* 
=========================================================================
Product Report
=========================================================================
Purpose: 
	- This report consolidates key product metrics and behaviours.

Highlights:
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
=========================================================================
*/
CREATE VIEW gold.report_products AS
WITH cte_base_query_2 AS (
/* ------------------------------------------------------------
1) Base Query: Retrieves core columns from Tables
   ------------------------------------------------------------
*/
	SELECT
		f.order_number,
		f.order_date,
		f.customer_key,
		f.sales_amount,
		f.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
		
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	WHERE order_date IS NOT NULL
	),

cte_product_aggregation AS(
/* ------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
   -------------------------------------------------------------------
*/


	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
		MAX(order_date) AS last_sale_date,
		DATEDIFF(MONTH, MAX(order_date), GETDATE()) AS recency_in_months,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF(quantity,0)), 1) AS avg_selling_price
		
	FROM cte_base_query_2
	GROUP BY 
		product_key,
		product_name,
		category,
		subcategory,
		cost
)

/* ------------------------------------------------------------------
3) Final Query: Combines all product results into one output
   -------------------------------------------------------------------
*/
SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		last_sale_date,
		recency_in_months,
  	CASE 
  		WHEN total_sales > 50000 THEN 'High performer'
  		WHEN total_sales >= 10000 THEN 'Mid range'
  		ELSE 'Low performer'
  	END AS product_segement,
  	lifespan,
  	total_orders,
  	total_sales,
  	total_quantity,
  	total_customers,
	-- Compute average order value (AVO)
  	CASE 
  		WHEN total_orders = 0 THEN 0
  		ELSE total_sales/total_orders
  	END AS avg_order_value,
  	-- compute average monthly spent
  	CASE
  		WHEN lifespan = 0 THEN total_sales
  		ELSE total_sales/lifespan
  	END AS avg_monthly_spent

FROM cte_product_aggregation
