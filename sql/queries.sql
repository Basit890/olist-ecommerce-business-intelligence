
-- ========================================================
-- PROJECT: Olist E-commerce Analytics
-- SECTION: 01 - SQL Queries
-- DATABASE: olist_ecommerce
-- TOOL: MySQL 9.2
-- =====================================================

USE olist_ecommerce;


-- 1. Retrieve the latest five orders
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM orders
ORDER BY order_purchase_timestamp DESC
LIMIT 5;


-- 2. Filter delivered orders
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
LIMIT 10;


-- 3. Retrieve orders from 2018
SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM orders
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp < '2019-01-01'
LIMIT 10;


-- 4. Filter multiple order statuses using IN
SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM orders
WHERE order_status IN ('delivered', 'shipped', 'canceled')
LIMIT 15;


-- 5. Exclude selected order statuses using NOT IN
SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM orders
WHERE order_status NOT IN ('delivered', 'canceled')
LIMIT 15;


-- 6. Search customer cities beginning with 's'
SELECT
    customer_id,
    customer_city,
    customer_state
FROM customers
WHERE customer_city LIKE 's%'
LIMIT 15;


-- 7. Find orders with missing approval timestamps
SELECT
    order_id,
    order_status,
    order_approved_at
FROM orders
WHERE order_approved_at IS NULL
LIMIT 15;


-- 8. Find orders with recorded approval timestamps
SELECT
    order_id,
    order_status,
    order_approved_at
FROM orders
WHERE order_approved_at IS NOT NULL
LIMIT 15;

-- 9. Retrieve unique order statuses
SELECT DISTINCT
    order_status
FROM orders;

-- 10. Count total orders
SELECT
    COUNT(*) AS total_orders
FROM orders;

-- 11. Count unique customers
SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- 12. Calculate average payment value
SELECT
    AVG(payment_value) AS average_payment_value
FROM payments;

-- 13. Find minimum and maximum payment values
SELECT
    MIN(payment_value) AS minimum_payment,
    MAX(payment_value) AS maximum_payment
FROM payments;

-- 14. Count orders by status
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 15. Analyze payment methods
SELECT
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_payment_value
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- 16. Calculate average payment by payment method
SELECT
    payment_type,
    COUNT(*) AS total_transactions,
    AVG(payment_value) AS average_payment_value
FROM payments
GROUP BY payment_type
ORDER BY average_payment_value DESC;

-- 17. Filter payment methods by transaction count
SELECT
    payment_type,
    COUNT(*) AS total_transactions
FROM payments
GROUP BY payment_type
HAVING COUNT(*) > 1000
ORDER BY total_transactions DESC;

-- 18. Categorize orders using CASE WHEN
SELECT
    order_status,
    COUNT(*) AS total_orders,
    CASE
        WHEN order_status = 'delivered' THEN 'Completed'
        ELSE 'Not Completed'
    END AS delivery_category
FROM orders
GROUP BY order_status;

