-- =====================================================================
-- Olist E-Commerce Sales Analysis: queries ported from SQLite to Databricks SQL
-- Catalog: workspace | Schema: olist | Source tables: silver_* (Delta, Unity Catalog)
--
-- Syntax differences from the SQLite versions:
--   * Tables are referenced as catalog.schema.table (three-part names)
--   * strftime('%Y-%m', ts)        -> date_format(ts, 'yyyy-MM')
--   * strftime('%Y-%m-01', ts)     -> trunc(ts, 'MM')
--   * julianday(a) - julianday(b)  -> (unix_timestamp(a) - unix_timestamp(b)) / 86400
--   * Category COALESCE / translation join moved into silver_products.category
-- Run each statement separately in the Databricks SQL Editor.
-- =====================================================================


-- 01. Headline numbers: delivered orders only, revenue = item price (freight excluded)
SELECT
    COUNT(DISTINCT o.order_id)        AS delivered_orders,
    COUNT(*)                          AS items_sold,
    ROUND(SUM(oi.price), 2)           AS total_revenue,
    ROUND(SUM(oi.freight_value), 2)   AS total_freight
FROM workspace.olist.silver_orders o
JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- 02. Monthly revenue, order count and month-over-month growth (CTE + LAG window function)
WITH monthly AS (
    SELECT
        date_format(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        COUNT(DISTINCT o.order_id)                          AS orders,
        SUM(oi.price)                                       AS revenue
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
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


-- 02b. Dashboard version: Jan 2017 - Aug 2018 only
WITH monthly AS (
    SELECT
        date_format(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        COUNT(DISTINCT o.order_id)                          AS orders,
        SUM(oi.price)                                       AS revenue
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND date_format(o.order_purchase_timestamp, 'yyyy-MM') BETWEEN '2017-01' AND '2018-08'
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


-- 03. Revenue by product category, with share and cumulative share (RANK + running SUM windows)
WITH category_revenue AS (
    SELECT
        p.category                       AS category,
        COUNT(DISTINCT o.order_id)       AS orders,
        SUM(oi.price)                    AS revenue
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
    JOIN workspace.olist.silver_products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.category
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


-- 04. Delivered orders and revenue by customer state, with shares and cumulative share
WITH state_sales AS (
    SELECT
        c.customer_state             AS state,
        COUNT(DISTINCT o.order_id)   AS orders,
        SUM(oi.price)                AS revenue
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_customers c    ON c.customer_id = o.customer_id
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
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


-- 04b. Check: state totals must add up to the headline numbers
WITH state_sales AS (
    SELECT
        c.customer_state             AS state,
        COUNT(DISTINCT o.order_id)   AS orders,
        SUM(oi.price)                AS revenue
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_customers c    ON c.customer_id = o.customer_id
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT COUNT(*) AS states, SUM(orders) AS total_orders, ROUND(SUM(revenue), 2) AS total_revenue
FROM state_sales;


-- 05. Overall delivery performance (delivered orders that have a delivery date)
SELECT
    COUNT(*)                                                           AS delivered_with_date,
    ROUND(AVG((unix_timestamp(order_delivered_customer_date)
             - unix_timestamp(order_purchase_timestamp)) / 86400), 1)  AS avg_delivery_days,
    ROUND(AVG((unix_timestamp(order_estimated_delivery_date)
             - unix_timestamp(order_purchase_timestamp)) / 86400), 1)  AS avg_estimated_days,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                           THEN 1 ELSE 0 END) / COUNT(*), 1)           AS pct_late
FROM workspace.olist.silver_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


-- 05b. Delivery time and late rate by customer state (CTE, then aggregate)
WITH delivery AS (
    SELECT
        c.customer_state AS state,
        (unix_timestamp(o.order_delivered_customer_date)
          - unix_timestamp(o.order_purchase_timestamp)) / 86400  AS days,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
             THEN 1 ELSE 0 END                                   AS is_late
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    state,
    COUNT(*)                                  AS orders,
    ROUND(AVG(days), 1)                       AS avg_delivery_days,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 1) AS pct_late
FROM delivery
GROUP BY state
ORDER BY avg_delivery_days DESC;


-- 06. AOV = average of per-order revenue (item price only, delivered orders)
WITH order_values AS (
    SELECT
        o.order_id,
        SUM(oi.price) AS order_value
    FROM workspace.olist.silver_orders o
    JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    COUNT(*)                     AS orders,
    ROUND(SUM(order_value), 2)   AS total_revenue,
    ROUND(AVG(order_value), 2)   AS aov,
    ROUND(MIN(order_value), 2)   AS smallest_order,
    ROUND(MAX(order_value), 2)   AS largest_order
FROM order_values;


-- 07. One row per item sold (delivered orders), saved as a view
CREATE OR REPLACE VIEW workspace.olist.v_sales_detail AS
SELECT
    o.order_id,
    trunc(o.order_purchase_timestamp, 'MM')          AS order_month,
    c.customer_state                                 AS state,
    CASE
        WHEN c.customer_state IN ('AC','AP','AM','PA','RO','RR','TO')                THEN 'North'
        WHEN c.customer_state IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE')      THEN 'Northeast'
        WHEN c.customer_state IN ('DF','GO','MT','MS')                               THEN 'Central-West'
        WHEN c.customer_state IN ('ES','MG','RJ','SP')                               THEN 'Southeast'
        WHEN c.customer_state IN ('PR','RS','SC')                                    THEN 'South'
        ELSE 'Other'
    END                                              AS region,
    p.category                                       AS category,
    oi.price
FROM workspace.olist.silver_orders o
JOIN workspace.olist.silver_customers c    ON c.customer_id = o.customer_id
JOIN workspace.olist.silver_order_items oi ON oi.order_id = o.order_id
JOIN workspace.olist.silver_products p     ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered';
