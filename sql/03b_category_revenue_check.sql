-- Check: revenue after joining products must equal the Step 6 total (13221498.11)
SELECT ROUND(SUM(oi.price), 2) AS revenue_check
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered';
