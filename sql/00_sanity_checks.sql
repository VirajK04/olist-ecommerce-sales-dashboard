-- Confirms every table loaded with the expected number of rows
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
