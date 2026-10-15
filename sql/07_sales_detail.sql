-- One row per item sold (delivered orders). Feeds Power BI and the Excel pivot.
SELECT
    o.order_id,
    strftime('%Y-%m-01', o.order_purchase_timestamp) AS order_month,
    c.customer_state                                 AS state,
    CASE
        WHEN c.customer_state IN ('AC','AP','AM','PA','RO','RR','TO')                THEN 'North'
        WHEN c.customer_state IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE')      THEN 'Northeast'
        WHEN c.customer_state IN ('DF','GO','MT','MS')                               THEN 'Central-West'
        WHEN c.customer_state IN ('ES','MG','RJ','SP')                               THEN 'Southeast'
        WHEN c.customer_state IN ('PR','RS','SC')                                    THEN 'South'
        ELSE 'Other'
    END                                              AS region,
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'unknown')                              AS category,
    oi.price
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
LEFT JOIN category_translation t
       ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered';
