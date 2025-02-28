-- Question 1
SELECT customer_code, customer, market
FROM dim_customer
WHERE customer LIKE "%AtliQ Exclusive%" 
AND region = 'APAC' ;

-- Question 2
WITH unique_table AS (
    SELECT 
       COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN p.product_code END) AS unique_products_2020,
       COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN p.product_code END) AS unique_products_2021
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE fiscal_year IN (2020, 2021)
)
SELECT 
    unique_products_2020, unique_products_2021,
    ((unique_products_2021 - unique_products_2020) / NULLIF(unique_products_2020, 0) * 100) AS percentage_chg 
FROM unique_table;

-- Question 3
 SELECT segment,
        COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC ; 

-- Question 4
WITH segment_product_counts AS (
    SELECT 
        segment,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN p.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN p.product_code END) AS product_count_2021
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE fiscal_year IN (2020, 2021)
    GROUP BY segment
)
SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM segment_product_counts
ORDER BY difference DESC ;

-- Question 5
SELECT p.product_code, product, manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    OR manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- Question 6
SELECT pre.customer_code, c.customer, 
    AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM fact_pre_invoice_deductions pre
JOIN dim_customer c
ON c.customer_code = pre.customer_code
WHERE fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code, customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Question 7
SELECT 
	MONTH(date) AS Month,
    YEAR(date) AS Year,
    SUM(g.gross_price*s.sold_quantity) AS Gross_sales_Amount
FROM fact_sales_monthly s
   JOIN fact_gross_price g 
       ON s.product_code = g.product_code
   JOIN dim_customer c
       ON c.customer_code = s.customer_code
WHERE customer = 'Atliq Exclusive'
GROUP BY 
    YEAR(date), MONTH(date)
ORDER BY Year, Month;

-- Question 8
SELECT 
    CONCAT('Q', Quarter) AS Quarter,
    total_sold_quantity
FROM (
    SELECT 
        QUARTER(date) AS Quarter,
        SUM(sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly
    WHERE YEAR(date) = 2020
    GROUP BY QUARTER(date)
) AS QuarterlySales
ORDER BY total_sold_quantity DESC
LIMIT 5;

-- Question 9
WITH sales_2021 AS (
    SELECT channel,
           SUM(g.gross_price*s.sold_quantity) AS gross_sales
    FROM fact_sales_monthly s
        JOIN fact_gross_price g
            ON s.product_code = g.product_code
        JOIN dim_customer c
            ON c.customer_code = s.customer_code
    WHERE s.fiscal_year = 2021
    GROUP BY channel
),
total_sales_2021 AS (
    SELECT SUM(gross_sales) AS total_gross_sales
    FROM sales_2021
)
SELECT 
    channel,
    ROUND(gross_sales / 1000000, 2) AS gross_sales_mln,  -- Convert to millions and round to 2 decimal places
    ROUND((gross_sales / total_gross_sales) * 100, 2) AS percentage
FROM sales_2021, total_sales_2021
ORDER BY gross_sales DESC
LIMIT 1;

-- Question 10
WITH ranked_products AS (
    SELECT 
        division,
        s.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
    FROM fact_sales_monthly s
    JOIN dim_product p 
    ON s.product_code = p.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY division, s.product_code, p.product  -- Add GROUP BY for non-aggregated columns
)
SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;