-- Revenue by product category (delivered orders only), with share and cumulative share
WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 'unknown')              AS category,
        COUNT(DISTINCT o.order_id)       AS orders,
        SUM(oi.price)                    AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    LEFT JOIN category_translation t
           ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)                              AS revenue_rank,
    category,
    orders,
    ROUND(revenue, 2)                                                AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                 AS pct_of_revenue,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                                 AS cumulative_pct
FROM category_revenue
ORDER BY revenue DESC;
