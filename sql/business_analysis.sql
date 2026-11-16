/*
PROJECT: Brazilian Olist E-Commerce Analytics

PURPOSE:
Perform business analysis using MySQL to identify
sales trends, customer behaviour, seller performance,
delivery efficiency, and customer satisfaction.

DATABASE: olist_ecommerce
SQL DIALECT: MySQL 9.2

ANALYSIS:
1. Product category revenue contribution
2. Customer repeat-purchase analysis
3. Top 10 sellers by revenue
4. Delivery performance
5. Customer satisfaction by delivery status
*/
-- 1. Product category revenue and contribution to total revenue

SELECT
    p.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS category_revenue,
    ROUND(
        SUM(oi.price) * 100.0 /
        SUM(SUM(oi.price)) OVER (),
        2
    ) AS revenue_percentage
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english
ORDER BY category_revenue DESC
LIMIT 10;

-- 2. Customer repeat-purchase analysis

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders = 1 THEN 1 ELSE 0 END)
        AS one_time_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;

-- 3. Top 10 sellers by delivered revenue

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. Delivery performance analysis

SELECT
    COUNT(*) AS total_delivered_orders,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                SECOND,
                order_purchase_timestamp,
                order_delivered_customer_date
            ) / 86400
        ),
        2
    ) AS average_delivery_days,

    SUM(
        CASE
            WHEN DATE(order_delivered_customer_date)
                 > DATE(order_estimated_delivery_date)
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    ROUND(
        SUM(
            CASE
                WHEN DATE(order_delivered_customer_date)
                     > DATE(order_estimated_delivery_date)
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

  -- 5. Customer satisfaction by delivery status

SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date)
             > DATE(o.order_estimated_delivery_date)
            THEN 'Late'
        WHEN DATE(o.order_delivered_customer_date)
             < DATE(o.order_estimated_delivery_date)
            THEN 'Early'
        ELSE 'On Time'
    END AS delivery_status,

    COUNT(DISTINCT r.order_id) AS total_orders,

    ROUND(AVG(r.review_score), 2) AS average_review_score

FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status
ORDER BY average_review_score DESC;