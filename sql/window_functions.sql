-- 1. Rank each seller's orders by revenue
WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        SUM(oi.price) AS order_revenue
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, oi.order_id
)

SELECT
    seller_id,
    order_id,
    ROUND(order_revenue, 2) AS order_revenue,
    ROW_NUMBER() OVER (
        PARTITION BY seller_id
        ORDER BY order_revenue DESC
    ) AS seller_order_rank
FROM seller_revenue
ORDER BY seller_id, seller_order_rank
LIMIT 20;

-- 2. Rank sellers by total delivered product revenue
WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        SUM(oi.price) AS total_revenue
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)

SELECT
    seller_id,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank,
    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS dense_revenue_rank
FROM seller_revenue
ORDER BY total_revenue DESC
LIMIT 10;

