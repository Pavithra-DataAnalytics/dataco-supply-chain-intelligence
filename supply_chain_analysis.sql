-- =====================================================
-- PROJECT: DATACO SUPPLY CHAIN INTELLIGENCE
-- DATABASE: PostgreSQL  |  TOOL: DBeaver
-- SOURCE TABLE: staging.datacosupplychaindataset (loaded from DataCo.xlsx)
-- CLEAN VIEW:   staging.v_supply_chain_clean
-- ANALYSIS WINDOW: 2015-01-01 to 2017-09-30
-- =====================================================
-- Run the sections in order. Expected results are given in comments.
-- Money may differ from Python / Power BI by less than 1 because the source
-- columns are stored as REAL (4-byte approximate numbers).


-- =====================================================
-- 1. DATA CHECKS ON THE RAW TABLE (all 180,519 rows)
-- =====================================================

-- 1a. Row counts and totals. Expected: 180,519 items; 65,752 orders;
--     180,519 distinct items; 0 non-positive sales; 33,784 loss items;
--     gross about 36,784,734; net about 33,054,402; profit about 3,966,903.
SELECT
    COUNT(*)                                             AS total_items,
    COUNT(DISTINCT "Order Id")                           AS total_orders,
    COUNT(DISTINCT "Order Item Id")                      AS distinct_items,
    COUNT(*) FILTER (WHERE "Sales" <= 0)                 AS non_positive_sales,
    COUNT(*) FILTER (WHERE "Order Profit Per Order" < 0) AS loss_items,
    ROUND(SUM("Sales"::numeric), 2)                      AS gross_sales,
    ROUND(SUM("Order Item Total"::numeric), 2)           AS net_sales,
    ROUND(SUM("Order Profit Per Order"::numeric), 2)     AS total_profit
FROM staging.datacosupplychaindataset;


-- 1b. Date format check. The order date is stored as text in TWO formats.
--     Expected: 'M/D/YYYY text' = 109,416 rows; 'other' (MM-DD-YYYY) = 71,103 rows.
SELECT
    CASE
        WHEN "order date (DateOrders)" ~ '^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$' THEN 'M/D/YYYY text'
        WHEN "order date (DateOrders)" ~ '^\d{4}-\d{2}-\d{2}' THEN 'ISO yyyy-mm-dd'
        ELSE 'other'
    END AS date_format,
    COUNT(*) AS rows
FROM staging.datacosupplychaindataset
GROUP BY 1;


-- 1c. Proof that the date rule is right. Both formats are month first.
--     Expected: order_unparsed = 0; ship_unparsed = 0; days_match = 180,519;
--     first_order = 2015-01-01 00:00; last_order = 2018-01-31 23:38.
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
    COUNT(*)                                                           AS total_rows,
    COUNT(*) FILTER (WHERE order_ts IS NULL)                           AS order_unparsed,
    COUNT(*) FILTER (WHERE ship_ts IS NULL)                            AS ship_unparsed,
    COUNT(*) FILTER (WHERE ship_ts::date - order_ts::date = days_real) AS days_match,
    MIN(order_ts)                                                      AS first_order,
    MAX(order_ts)                                                      AS last_order
FROM parsed;


-- =====================================================
-- 2. CLEAN VIEW
-- Gives every query clean names, parsed dates, numeric money columns and
-- the analysis-window flag, so the rules are defined once.
-- =====================================================
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


-- =====================================================
-- 3. KPI RECONCILIATION WITH PYTHON AND POWER BI
-- Expected: items 171,962; orders 57,349; gross about 34,248,265;
-- net about 30,774,234; profit 3,685,985.03; margin 11.98;
-- avg order value 536.61; late delivery rate 57.28.
-- =====================================================
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


-- 3b. By year. Expected orders: 2015 = 20,904; 2016 = 20,859; 2017 = 15,586.
SELECT
    EXTRACT(YEAR FROM order_date)::int           AS order_year,
    COUNT(DISTINCT order_id)                     AS orders,
    ROUND(SUM(net_sales), 2)                     AS net_sales
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY 1
ORDER BY 1;


-- =====================================================
-- 4. DELIVERY: LATE RATE BY SHIPPING MODE
-- Canceled shipments are excluded from the denominator.
-- Expected: First Class 100.00; Second Class 79.81; Same Day 47.71; Standard Class 39.78.
-- =====================================================
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


-- =====================================================
-- 5. MONTHLY TREND
-- Expected: 33 rows; 2015-01 net sales about 945,382.
-- =====================================================
SELECT
    order_month,
    COUNT(DISTINCT order_id)                         AS orders,
    ROUND(SUM(net_sales), 2)                         AS net_sales,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 2)   AS profit_margin_pct
FROM staging.v_supply_chain_clean
WHERE in_analysis_window
GROUP BY order_month
ORDER BY order_month;


-- =====================================================
-- 6. LOSS-MAKING ITEMS BY CATEGORY
-- Expected totals: 32,179 loss items; loss amount about -3,617,894.
-- Largest losses: Fishing, Cleats, Camping & Hiking.
-- =====================================================
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


-- =====================================================
-- 7. MARKET PERFORMANCE AT ORDER GRAIN
-- Expected orders: LATAM 17,181; Europe 15,778; Pacific Asia 11,957;
-- USCA 8,579; Africa 3,854 (total 57,349).
-- NOTE: markets sold in separate blocks of months, so these totals reflect
-- how long each market was active, not demand. Compare rates, not volume.
-- =====================================================
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

-- =====================================================
-- END OF SCRIPT
-- =====================================================
