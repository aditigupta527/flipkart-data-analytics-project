CREATE DATABASE flipkart_db;
USE flipkart_db;

-- Primary Keys

ALTER TABLE dim_users
ADD primary key(user_id);

ALTER TABLE dim_products
ADD primary key(product_id);

ALTER TABLE fact_orders
ADD primary key(order_id);

ALTER TABLE fact_payments
ADD primary key(payment_id);

-- Foreign Keys

ALTER TABLE fact_orders
ADD constraint fk_fact_orders
foreign key (user_id)
references dim_users (user_id);

ALTER TABLE fact_orders
ADD constraint fk_fact_orders_products
foreign key (product_id)
references dim_products (product_id);

ALTER TABLE fact_payments
ADD constraint fk_payments_orders
foreign key (order_id)
references fact_orders (order_id);

-- Verify
SHOW TABLES;
select * from dim_users;
select * from dim_products;
select * from fact_orders;
select * from fact_payments;


-- Query 1 — Revenue by Category--- which categories dominate?

SELECT 
P.category,
COUNT(o.order_id) as total_orders,
ROUND(SUM(o.total_amount),2) as total_revenue,
ROUND(AVG(o.total_amount),2) as avg_revenue,
CONCAT(ROUND(SUM(o.total_amount)*100 /
(SELECT SUM(total_amount) FROM fact_orders),1),'%') AS revenue_pct
FROM fact_orders as o
join dim_products as p
on o.product_id=p.product_id
group by p.category
ORDER BY total_revenue DESC;

-- Query 2 — Revenue by Customer Segment

SELECT u.user_segment,
COUNT(DISTINCT o.user_id) as unique_customers,
COUNT(o.order_id) as total_orders,
ROUND(SUM(o.total_amount), 2)  AS total_revenue,
ROUND(AVG(o.total_amount), 2)  AS avg_order_value,
ROUND(AVG(o.discount_pct), 2)  AS avg_discount_given
FROM fact_orders o
JOIN dim_users u ON o.user_id = u.user_id
GROUP BY u.user_segment
ORDER BY total_revenue DESC;


-- Query 3 — Year-over-Year Revenue Growth

WITH YEARLY_DATA AS(
     SELECT
          order_year,
          count(order_id) as total_orders,
          SUM(total_amount) AS yearly_revenue,
          AVG(total_amount) AS avg_order_value
	 FROM fact_orders
     WHERE order_status='Completed'
     GROUP BY order_year
)
SELECT
     order_year,
     total_orders,
     ROUND(yearly_revenue,2)AS yearly_revenue,
	 ROUND(avg_order_value,2)AS avg_order_value,
     ROUND(LAG(yearly_revenue) OVER (ORDER BY order_year),2)AS prev_year_revenue,
     CONCAT(ROUND((yearly_revenue - LAG(yearly_revenue) OVER (ORDER BY order_year))
     /LAG(yearly_revenue) OVER (ORDER BY order_year) * 100,1),'%')AS yoy_growth_pct
FROM yearly_data
ORDER BY order_year;
-- Query 4 — Return and Cancellation Rate

SELECT 
      p.category,
      COUNT(*) AS total_orders,
      SUM(CASE WHEN o.order_status='Returned' THEN 1 ELSE 0 END) AS returns,
      SUM(CASE WHEN o.order_status='Cancelled' THEN 1 ELSE 0 END) AS cancellations,
	  CONCAT(ROUND(SUM(CASE WHEN o.order_status='Returned'  THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS return_rate_pct,
	  CONCAT(ROUND(SUM(CASE WHEN o.order_status='Cancelled'  THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS cancel_rate_pct
FROM fact_orders as o
JOIN dim_products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- Query 5 — Discount Impact

SELECT 
     CASE 
         WHEN discount_pct =0 THEN 'No Discount'
         WHEN discount_pct <=5 THEN '1-5%'
         WHEN discount_pct <=10 THEN '6-10%'
         WHEN discount_pct <=15 THEN '11-15%'
         WHEN discount_pct <= 20     THEN '16-20%'
        ELSE                             '20%+'
    END                             AS discount_band,
    COUNT(order_id) as total_orders,
    ROUND(AVG(total_amount), 2)     AS avg_order_value,
        ROUND(SUM(total_amount), 2)     AS total_revenue
FROM fact_orders
WHERE order_status = 'Completed'
GROUP BY discount_band
ORDER BY avg_order_value DESC;


-- Query 6 — Fraud Analysis by Payment Method

SELECT 
     p.payment_method,
     COUNT(*) as total_rows,
     SUM(p.is_fraud) as fraud_count,
     CONCAT(ROUND(SUM(p.is_fraud)*100.0/COUNT(*), 2),'%')AS fraud_rate_pct,
     ROUND(SUM(CASE WHEN p.is_fraud=1
           THEN o.total_amount 
           ELSE 0
           END),2) as fraud_revenue_risk
FROM fact_payments as p
JOIN fact_orders as o
ON p.order_id = o.order_id
GROUP BY p.payment_method
ORDER BY fraud_rate_pct DESC;

-- Query 7 — Monthly Revenue with Quarterly Breakdown

SELECT
    order_year,
    order_quarter,
    order_month_name,
    COUNT(order_id)               AS total_orders,
    ROUND(SUM(total_amount), 2)   AS monthly_revenue
FROM fact_orders
WHERE order_status = 'Completed'
GROUP BY order_year, order_quarter, order_month, order_month_name
ORDER BY order_year, order_month;

-- Query 8 — Top 10 Customers by Lifetime Value



SELECT
    o.user_id,
    u.user_segment,
    COUNT(o.order_id)              AS total_orders,
    ROUND(SUM(o.total_amount), 2)  AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)  AS avg_order_value,
    ROUND(AVG(o.discount_pct), 2)  AS avg_discount
FROM fact_orders o
JOIN dim_users u ON o.user_id = u.user_id
WHERE o.order_status = 'Completed'
GROUP BY o.user_id, u.user_segment
ORDER BY lifetime_value DESC
LIMIT 10;

     
     
     
     


      
      



     



