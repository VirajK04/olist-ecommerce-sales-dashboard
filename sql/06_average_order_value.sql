-- AOV = average of per-order revenue (item price only, delivered orders)
WITH order_values AS (
    SELECT
        o.order_id,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    COUNT(*)                     AS orders,
    ROUND(SUM(order_value), 2)   AS total_revenue,
    ROUND(AVG(order_value), 2)   AS aov,
    ROUND(MIN(order_value), 2)   AS smallest_order,
    ROUND(MAX(order_value), 2)   AS largest_order
FROM order_values;
