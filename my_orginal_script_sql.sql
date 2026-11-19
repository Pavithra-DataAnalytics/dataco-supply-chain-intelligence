-- 1. DATABASE EXPLORATION

select current_database();

select table_schema, table_name
from information_schema.tables
where table_schema = 'staging'
 and table_name = 'datacosupplychaindataset';

-- 2. DATASET EXPLORATION

select count(*) as total_records
from staging.datacosupplychaindataset;

select*
from staging.datacosupplychaindataset
limit 10;

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'datacosupplychaindataset'
  AND column_name ILIKE '%date%';

-- 3. SALES AND PROFIT ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

SELECT
    ROUND(SUM("Sales"::numeric), 2) AS total_sales
FROM staging.datacosupplychaindataset;


SELECT
    ROUND(SUM("Order Profit Per Order"::numeric), 2) AS total_profit
FROM staging.datacosupplychaindataset;

-- 4. DELIVERY STATUS ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

select
   "Delivery Status",
   count(*) as total_order_items
from staging.datacosupplychaindataset
group by "Delivery Status"
order by total_order_items desc;

-- 5. SHIPPING MODE ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

select
  "Shipping Mode",
  count(*) as total_order_items
from staging.datacosupplychaindataset
group by "Shipping Mode"
order by total_order_items desc;

SELECT
    "Shipping Mode",
    COUNT(*) AS total_order_items,
    ROUND(SUM("Sales"::numeric), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2) AS total_profit,
    ROUND(
        AVG("Days for shipping (real)")::numeric,
        2
    ) AS avg_shipping_days
FROM staging.datacosupplychaindataset
GROUP BY "Shipping Mode"
ORDER BY total_sales DESC;


-- 6. LATE DELIVERY RISK ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'datacosupplychaindataset'
  AND column_name = 'Late_delivery_risk';

SELECT DISTINCT
    "Late_delivery_risk"
FROM staging.datacosupplychaindataset
ORDER BY 1;

SELECT
    "Shipping Mode",
    COUNT(*) FILTER (WHERE "Delivery Status" <> 'Shipping canceled')  AS delivered_items,
    COUNT(*) FILTER (WHERE "Late_delivery_risk" = 1)                  AS late_items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Late_delivery_risk" = 1)
          / COUNT(*) FILTER (WHERE "Delivery Status" <> 'Shipping canceled'), 2) AS late_delivery_rate_pct
FROM staging.datacosupplychaindataset
GROUP BY "Shipping Mode"
ORDER BY late_delivery_rate_pct DESC;

-- 7. CATEGORY PERFORMANCE ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

SELECT
    "Category Name",
    COUNT(*) AS total_order_items,
    ROUND(SUM("Sales"::numeric), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2) AS total_profit
FROM staging.datacosupplychaindataset
GROUP BY "Category Name"
ORDER BY total_profit DESC;

-- 8. MARKET PERFORMANCE ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.

SELECT
    "Market",
    COUNT(*) AS total_order_items,
    ROUND(SUM("Sales"::numeric), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2) AS total_profit
FROM staging.datacosupplychaindataset
GROUP BY "Market"
ORDER BY total_sales desc;


-- 9. REGIONAL PERFORMANCE ANALYSIS
-- NOTE: sections 3 to 9 use all dates (Jan 2015 to Jan 2018).
-- The dashboard uses the analysis window (Jan 2015 to Sep 2017); see sections after 10.


SELECT
    "Order Region",
    COUNT(*) AS total_order_items,
    ROUND(SUM("Sales"::numeric), 2) AS total_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2) AS total_profit
FROM staging.datacosupplychaindataset
GROUP BY "Order Region"
ORDER BY total_sales DESC;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'datacosupplychaindataset'
  AND (column_name ILIKE '%date%' OR column_name IN ('Sales', 'Order Item Total', 'Order Id'))
ORDER BY column_name;

 -- 10. DATA QUALITY AND RECONCILIATION CHECKS
-- Purpose: Verify counts, totals and date format

SELECT
    COUNT(*)                                                  AS total_items,
    COUNT(DISTINCT "Order Id")                                AS total_orders,
    COUNT(DISTINCT "Order Item Id")                           AS distinct_items,
    COUNT(*) FILTER (WHERE "Sales" <= 0)                      AS non_positive_sales,
    COUNT(*) FILTER (WHERE "Order Profit Per Order" < 0)      AS loss_items,
    ROUND(SUM("Sales"::numeric), 2)                           AS gross_sales,
    ROUND(SUM("Order Item Total"::numeric), 2)                AS net_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2)          AS total_profit
FROM staging.datacosupplychaindataset;


SELECT "order date (DateOrders)", "shipping date (DateOrders)", "Days for shipping (real)"
FROM staging.datacosupplychaindataset
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$') AS rows_matching_pattern,
    MAX(split_part(split_part("order date (DateOrders)", ' ', 1), '/', 1)::int)
        FILTER (WHERE "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$') AS max_first_part,
    MAX(split_part(split_part("order date (DateOrders)", ' ', 1), '/', 2)::int)
        FILTER (WHERE "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$') AS max_second_part
FROM staging.datacosupplychaindataset;

SELECT "order date (DateOrders)", "shipping date (DateOrders)", "Days for shipping (real)"
FROM staging.datacosupplychaindataset
WHERE NOT ("order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$')
LIMIT 10;

SELECT
    CASE
        WHEN "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$' THEN 'M/D/YYYY text'
        WHEN "order date (DateOrders)" ~ '^\d{4}-\d{2}-\d{2}' THEN 'ISO yyyy-mm-dd'
        ELSE 'other'
    END AS date_format,
    COUNT(*) AS rows
FROM staging.datacosupplychaindataset
GROUP BY 1;

WITH parsed AS (
    SELECT
        "Days for shipping (real)" AS days_real,
        CASE
            WHEN "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$'
                THEN TO_TIMESTAMP("order date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp
            WHEN "order date (DateOrders)" ~ '^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$'
                THEN TO_TIMESTAMP("order date (DateOrders)", 'MM-DD-YYYY HH24:MI')::timestamp
        END AS order_ts,
        CASE
            WHEN "shipping date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$'
                THEN TO_TIMESTAMP("shipping date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp
            WHEN "shipping date (DateOrders)" ~ '^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$'
                THEN TO_TIMESTAMP("shipping date (DateOrders)", 'MM-DD-YYYY HH24:MI')::timestamp
        END AS ship_ts
    FROM staging.datacosupplychaindataset
)
SELECT
    COUNT(*)                                                    AS total_rows,
    COUNT(*) FILTER (WHERE order_ts IS NULL)                    AS order_unparsed,
    COUNT(*) FILTER (WHERE ship_ts IS NULL)                     AS ship_unparsed,
    COUNT(*) FILTER (WHERE ship_ts::date - order_ts::date = days_real) AS days_match,
    MIN(order_ts)                                               AS first_order,
    MAX(order_ts)                                               AS last_order
FROM parsed;

CREATE OR REPLACE VIEW staging.v_supply_chain_clean AS
WITH parsed AS (
    SELECT
        t.*,
        CASE
            WHEN t."order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$'
                THEN TO_TIMESTAMP(t."order date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp
            WHEN t."order date (DateOrders)" ~ '^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$'
                THEN TO_TIMESTAMP(t."order date (DateOrders)", 'MM-DD-YYYY HH24:MI')::timestamp
        END AS order_ts,
        CASE
            WHEN t."shipping date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$'
                THEN TO_TIMESTAMP(t."shipping date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp
            WHEN t."shipping date (DateOrders)" ~ '^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$'
                THEN TO_TIMESTAMP(t."shipping date (DateOrders)", 'MM-DD-YYYY HH24:MI')::timestamp
        END AS ship_ts
    FROM staging.datacosupplychaindataset t
)
SELECT
    "Order Id"                                         AS order_id,
    "Order Item Id"                                    AS order_item_id,
    order_ts,
    order_ts::date                                     AS order_date,
    DATE_TRUNC('month', order_ts)::date                AS order_month,
    ship_ts,
    (order_ts::date BETWEEN DATE '2015-01-01' AND DATE '2017-09-30') AS in_analysis_window,
    ROUND("Sales"::numeric, 2)                         AS gross_sales,
    ROUND("Order Item Total"::numeric, 2)              AS net_sales,
    ROUND("Order Profit Per Order"::numeric, 2)        AS profit,
    "Order Item Quantity"                              AS quantity,
    "Days for shipping (real)"                         AS days_shipping_real,
    "Days for shipment (scheduled)"                    AS days_shipping_scheduled,
    "Delivery Status"                                  AS delivery_status,
    ("Delivery Status" = 'Shipping canceled')          AS is_shipping_canceled,
    "Late_delivery_risk"                               AS late_delivery_flag,
    "Shipping Mode"                                    AS shipping_mode,
    "Order Status"                                     AS order_status,
    "Category Name"                                    AS category_name,
    "Department Name"                                  AS department_name,
    "Market"                                           AS market,
    "Order Region"                                     AS order_region,
    "Order Country"                                    AS order_country,
    "Customer Id"                                      AS customer_id,
    "Customer Segment"                                 AS customer_segment
FROM parsed;

SELECT
    COUNT(*)                                                         AS items,
    COUNT(DISTINCT order_id)                                         AS orders,
    ROUND(SUM(gross_sales), 2)                                       AS gross_sales,
    ROUND(SUM(net_sales), 2)                                         AS net_sales,
    ROUND(SUM(profit), 2)                                            AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 2)                   AS profit_margin_pct,
    ROUND(SUM(net_sales) / COUNT(DISTINCT order_id), 2)              AS avg_order_value,
    ROUND(100.0 * COUNT(*) FILTER (WHERE late_delivery_flag = 1)
          / COUNT(*) FILTER (WHERE NOT is_shipping_canceled), 2)     AS late_delivery_rate_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window;

SELECT
    EXTRACT(YEAR FROM order_date)::int           AS order_year,
    COUNT(DISTINCT order_id)                     AS orders,
    ROUND(SUM(net_sales), 2)                     AS net_sales
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY 1
ORDER BY 1;

SELECT
    shipping_mode,
    COUNT(*) FILTER (WHERE NOT is_shipping_canceled)                      AS delivered_items,
    COUNT(*) FILTER (WHERE late_delivery_flag = 1)                        AS late_items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE late_delivery_flag = 1)
          / COUNT(*) FILTER (WHERE NOT is_shipping_canceled), 2)          AS late_delivery_rate_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY shipping_mode
ORDER BY late_delivery_rate_pct DESC;

SELECT
    order_month,
    COUNT(DISTINCT order_id)                         AS orders,
    ROUND(SUM(net_sales), 2)                         AS net_sales,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 2)   AS profit_margin_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY order_month
ORDER BY order_month;

SELECT
    category_name,
    COUNT(*)                                                         AS items,
    COUNT(*) FILTER (WHERE profit < 0)                               AS loss_items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE profit < 0) / COUNT(*), 1)  AS loss_item_pct,
    ROUND(SUM(profit) FILTER (WHERE profit < 0), 2)                  AS loss_amount,
    ROUND(SUM(profit), 2)                                            AS net_profit,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 2)                   AS margin_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY category_name
ORDER BY loss_amount;

SELECT
    market,
    COUNT(DISTINCT order_id)                        AS orders,
    ROUND(SUM(net_sales), 2)                        AS net_sales,
    ROUND(SUM(profit), 2)                           AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 2)  AS profit_margin_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY market
ORDER BY net_sales DESC;

-- END OF SUPPLY CHAIN ANALYTICS SQL PROJECT