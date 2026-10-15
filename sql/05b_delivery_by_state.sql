-- Delivery time and late rate by customer state (CTE, then aggregate)
WITH delivery AS (
    SELECT
        c.customer_state AS state,
        julianday(o.order_delivered_customer_date)
          - julianday(o.order_purchase_timestamp)           AS days,
        CASE WHEN julianday(o.order_delivered_customer_date)
                > julianday(o.order_estimated_delivery_date)
             THEN 1 ELSE 0 END                              AS is_late
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    state,
    COUNT(*)                              AS orders,
    ROUND(AVG(days), 1)                   AS avg_delivery_days,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 1) AS pct_late
FROM delivery
GROUP BY state
ORDER BY avg_delivery_days DESC;
