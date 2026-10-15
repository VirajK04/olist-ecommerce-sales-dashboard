-- Headline numbers: delivered orders only, revenue = item price (freight excluded)
SELECT
    COUNT(DISTINCT o.order_id)        AS delivered_orders,
    COUNT(*)                          AS items_sold,
    ROUND(SUM(oi.price), 2)           AS total_revenue,
    ROUND(SUM(oi.freight_value), 2)   AS total_freight
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';
