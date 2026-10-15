-- Monthly revenue, order count and month-over-month growth (delivered orders only)
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS month,
        COUNT(DISTINCT o.order_id)                    AS orders,
        SUM(oi.price)                                 AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    month,
    orders,
    ROUND(revenue, 2)                                           AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)                AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1)   AS mom_growth_pct
FROM monthly
ORDER BY month;
