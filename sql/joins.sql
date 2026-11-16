-- 19. Join orders with customer information
SELECT
    o.order_id,
    o.order_status,
    c.customer_city,
    c.customer_state
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
LIMIT 15;

-- 20. Find customers without orders
SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 21. Join orders, order_items and products
SELECT
    o.order_id,
    o.order_status,
    oi.product_id,
    p.product_category_name_english,
    oi.price
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
INNER JOIN products p
    ON oi.product_id = p.product_id
LIMIT 15;

-- 22. Find top 10 product categories by delivered product revenue
SELECT
    p.product_category_name_english,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
INNER JOIN orders o
    ON oi.order_id = o.order_id
INNER JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- 23. Calculate total recorded payment for each delivered order
SELECT
    o.order_id,
    o.order_status,
    COUNT(p.payment_sequential) AS payment_transactions,
    ROUND(SUM(p.payment_value), 2) AS total_payment
FROM orders o
INNER JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.order_id, o.order_status
ORDER BY total_payment DESC
LIMIT 15;

-- 7. Find the top 10 states by delivered order volume
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;