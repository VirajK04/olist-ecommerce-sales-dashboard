-- Check: state totals must add up to the Step 6 headline numbers
WITH state_sales AS (
    SELECT
        c.customer_state             AS state,
        COUNT(DISTINCT o.order_id)   AS orders,
        SUM(oi.price)                AS revenue
    FROM orders o
    JOIN customers c    ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT COUNT(*) AS states, SUM(orders) AS total_orders, ROUND(SUM(revenue), 2) AS total_revenue
FROM state_sales;
