-- Overall delivery performance (delivered orders that have a delivery date)
SELECT
    COUNT(*)                                                         AS delivered_with_date,
    ROUND(AVG(julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)), 1)               AS avg_delivery_days,
    ROUND(AVG(julianday(order_estimated_delivery_date)
            - julianday(order_purchase_timestamp)), 1)               AS avg_estimated_days,
    ROUND(100.0 * SUM(CASE WHEN julianday(order_delivered_customer_date)
                            > julianday(order_estimated_delivery_date)
                           THEN 1 ELSE 0 END) / COUNT(*), 1)         AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
