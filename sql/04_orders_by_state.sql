-- Delivered orders and revenue by customer state, with shares and cumulative share
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
SELECT
    RANK() OVER (ORDER BY revenue DESC)                          AS revenue_rank,
    state,
    orders,
    ROUND(revenue, 2)                                            AS revenue,
    ROUND(100.0 * orders / SUM(orders) OVER (), 2)               AS pct_of_orders,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)             AS pct_of_revenue,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                             AS cumulative_pct
FROM state_sales
ORDER BY revenue DESC;
