# DataCo Supply Chain Intelligence

An end-to-end analytics project on the public DataCo supply chain dataset, built with **SQL (PostgreSQL), Python, Power BI and AI**. SQL, Python and Power BI reproduce the same KPIs, and the AI components were tested honestly, including the ideas that did not work.

!\[Executive Overview]<img width="869" height="489" alt="Supply Chain 1" src="https://github.com/user-attachments/assets/c4b5fcbd-b801-4be7-9a17-cbbe727e91cb" />


## Headline results (Jan 2015 to Sep 2017)

|KPI|Value|
|-|-|
|Orders|57,349 (171,962 order items)|
|Net sales (after discount)|30.77M|
|Profit / margin|3.69M / 11.98%|
|Average order value|536.61|
|Late delivery rate|57.28%|
|Customers / orders per customer|12,330 / 4.65|

## What I found

* **Late deliveries depend on shipping mode, not on market or time.** First Class 100%, Second Class 79.81%, Same Day 47.71%, Standard Class 39.78%.
* **Same Day has a noon cutoff.** Orders placed before 12:00 are never late; orders at 12:00 or later are always late.
* **About 1 in 5 items (18.7%) loses money (-3.62M),** and no available field explains why (discount, shipping mode, segment, market and category all show the same rate).
* **Sales are flat because the customer base is closed.** New customers fell from 1,895 (2016) to 304 (2017, Jan to Sep), while 95.4% of customers reorder.

## A data problem found and fixed

The order date column in `DataCo.xlsx` mixes two formats: 109,416 text dates, and 71,103 real Excel dates stored with **day and month swapped**. Left alone, these rows land in the wrong months. After parsing both formats explicitly, *shipping date minus order date* equals the recorded shipping days on **all 180,519 rows** (it matched only about half before the fix).

## AI components

|Component|Result|
|-|-|
|Late-delivery risk scoring|72.2% accuracy, AUC 0.77 on 2017 test data. Matches a four-line rule; its value is calibrated probabilities (High band: 89.5% actually late)|
|Baseline monthly forecast|About 1,738 orders and 1.0M net sales per month; backtest error 2.1% (orders) and 3.0% (net sales)|
|AI-written insights|Script builds a verified KPI summary and a prompt so an LLM can only use checked numbers|
|Tested and rejected|Profit/loss prediction (AUC 0.50, no signal); forecasting by market or category (markets sell in blocks of months)|

## Power BI dashboard (6 pages)

Executive Overview, Product Intelligence, Shipping \& Logistics, Customer Intelligence, Regional Analysis, AI Insights. Screenshots are in `powerbi/screenshots/`.
<img width="869" height="489" alt="Supply Chain 1" src="https://github.com/user-attachments/assets/1665d7a9-7153-40d9-bbe3-1d887eacd827" />
<img width="867" height="487" alt="Supply Chain 2" src="https://github.com/user-attachments/assets/67e3c8d6-ac7c-432c-9263-859c67d03453" />
<img width="869" height="488" alt="Supply Chain 3" src="https://github.com/user-attachments/assets/eb23eb57-be3a-41cb-99cc-870164b79992" />
<img width="871" height="488" alt="Supply Chain 4" src="https://github.com/user-attachments/assets/058d98fc-430a-40a6-b4ae-512d68454c4b" />
<img width="873" height="486" alt="Supply chain 5" src="https://github.com/user-attachments/assets/e36ff9d6-64ef-41ae-b692-49c6dfdcd860" />
<img width="869" height="489" alt="Supply chain 6" src="https://github.com/user-attachments/assets/d130a9b5-2425-4f5f-912c-f53f3073b734" />


## Repository structure

```
sql/        supply\\\_chain\\\_analysis.sql        clean view + analysis + reconciliation queries
python/     supply\\\_chain\\\_eda\\\_v2.py           EDA with date fix and KPI reconciliation
            late\\\_delivery\\\_model.py           late-delivery risk model
            demand\\\_forecast\\\_baseline.py      baseline forecast with rolling backtest
            ai\\\_insights\\\_generator.py         verified summary + LLM prompt
outputs/    model\\\_metrics.csv, demand\\\_forecast.csv, forecast\\\_backtest.csv, kpi\\\_summary.json
powerbi/    screenshots/                     dashboard page images
docs/       final\\\_report.pdf                 full project report
```

## How to reproduce

1. Download the DataCo dataset (link below) and save it as `DataCo.xlsx` in the `python/` folder.
2. Install: `pip install pandas numpy matplotlib seaborn openpyxl scikit-learn`
3. Run in this order: `supply\\\_chain\\\_eda\\\_v2.py`, `late\\\_delivery\\\_model.py`, `demand\\\_forecast\\\_baseline.py`, `ai\\\_insights\\\_generator.py`.
4. Each script prints a check; the EDA script ends with a KPI reconciliation where every line should say `OK`.
5. For SQL: load the file into PostgreSQL as `staging.datacosupplychaindataset`, then run `sql/supply\\\_chain\\\_analysis.sql` section by section (expected results are in the comments).

## Business rules used everywhere

* **Analysis window:** 2015-01-01 to 2017-09-30. From October 2017 the data changes structure (about one item per order, much lower net sales), so it is excluded.
* **Net sales** = order item total (after discount). **Order** = distinct order id. **Item** = order line.
* **Late delivery rate** = late items / delivered items (canceled shipments excluded).

## Limitations

* No supplier, inventory or cost data, so supplier risk, inventory and margin-driver analysis are not possible.
* Delivery fields look simulated (for example First Class always takes exactly 2 days against a 1-day promise); findings are indicative.
* Markets sold in separate blocks of months, so market totals reflect active months, not demand.
* SQL money values can differ from Python and Power BI by less than 1 because the source columns are stored as `real`.

## Data

Public DataCo Smart Supply Chain dataset.(https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

## Author

**Pavithra R** | www.linkedin.com/in/pavithra-r-12p2003

