-- 1. Find products with at least one item priced above the overall average
SELECT
    product_id,
    product_category_name_english,
    product_name_lenght,
    product_weight_g
FROM products
WHERE product_id IN (
    SELECT product_id
    FROM order_items
    WHERE price > (
        SELECT AVG(price)
        FROM order_items
    )
)
LIMIT 15;

-- 2. Find categories with revenue above average category revenue
SELECT
    category_revenue.product_category_name_english,
    category_revenue.total_revenue
FROM (
    SELECT
        p.product_category_name_english,
        SUM(oi.price) AS total_revenue
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    INNER JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name_english
) AS category_revenue
WHERE category_revenue.total_revenue > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT
            p.product_category_name_english,
            SUM(oi.price) AS total_revenue
        FROM order_items oi
        INNER JOIN orders o
            ON oi.order_id = o.order_id
        INNER JOIN products p
            ON oi.product_id = p.product_id
        WHERE o.order_status = 'delivered'
        GROUP BY p.product_category_name_english
    ) AS average_category
)
ORDER BY category_revenue.total_revenue DESC;

-- 3. Find the top 10 product categories by delivered revenue using a CTE
WITH category_revenue AS (
    SELECT
        p.product_category_name_english,
        COUNT(*) AS total_items_sold,
        SUM(oi.price) AS total_revenue
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    INNER JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name_english
)

SELECT
    product_category_name_english,
    total_items_sold,
    ROUND(total_revenue, 2) AS total_revenue
FROM category_revenue
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. Calculate average order value and total revenue by customer state
WITH order_revenue AS (
    SELECT
        o.order_id,
        c.customer_state,
        SUM(oi.price) AS order_value
    FROM orders o
    INNER JOIN customers c
        ON o.customer_id = c.customer_id
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_state
)

SELECT
    customer_state,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_value), 2) AS average_order_value,
    ROUND(SUM(order_value), 2) AS total_revenue
FROM order_revenue
GROUP BY customer_state
ORDER BY average_order_value DESC
LIMIT 10;