# Olist E-Commerce Analytics

An analysis of the Brazilian Olist marketplace dataset: about 99,000 orders placed between September 2016 and August 2018. I wanted to answer a simple question: where does the business make its money, and where does it lose customers?

The work covers sales, customers, products, sellers, delivery performance and reviews. The findings are written up in a 14-slide presentation.

A Power BI dashboard has also been built for this project. Its files will be added to this repository later.

## What I found

All figures below are for delivered orders unless stated otherwise.

| Area | Result |
|---|---|
| Orders placed | 99,441 (96,478 delivered, 97.02%) |
| Product revenue | R$13.22M, plus R$2.20M in freight (R$15.42M total) |
| Average order value | R$137.04 (freight excluded) |
| Repeat buyers | 2,801 of 93,358 customers (3.00%) |
| Sellers | 3,095 registered, 2,970 with delivered sales; the top 10 earn 13.27% of revenue |
| Geography | São Paulo sellers: 64.36% (the rest of Brazil: 35.64%) |
| Delivery | 12.56 days on average; 6.77% of orders arrived late |
| Reviews | 4.09 average; 77.07% positive, 8.24% neutral, 14.69% negative |

The pattern that stood out most: late deliveries drag the average review score from about 4.29 (early) down to 2.27. Only 3% of customers ever come back, so fixing delivery and getting first-time buyers to return are the two biggest opportunities.

## Repository contents

- `sql/`: the MySQL queries (basic queries, joins, subqueries, window functions) and the business analysis script
- `notebooks/01_olist_ecommerce_analysis.ipynb`: the Python (Google Colab) notebook with the cleaning, missing-value checks and exploratory analysis
- `presentation/`: the slide deck, as an editable PowerPoint file and a PDF
- `scripts/profile_and_validate.py`: loads the cleaned CSVs, checks keys and relationships, and recalculates every number above so they can be verified

## How the numbers were defined

- Revenue is the item price on delivered orders. Freight is reported separately, and average order value excludes it.
- Repeat behaviour uses `customer_unique_id`, because `customer_id` changes with every order.
- A delivery counts as early, on time or late by comparing calendar dates, since the estimated date has no time of day.
- The late rate uses only delivered orders that have both a delivery date and an estimate (96,470).
- Recorded payments are kept apart from revenue, because they do not match item totals exactly on a small number of orders.

## Running the validation script

The data is not stored in this repository. Download the Olist cleaned CSV files separately, put them in one folder, then run:

```bash
pip install pandas
python3 scripts/profile_and_validate.py /path/to/folder
```

## Tools

Python (pandas, Google Colab), SQL, Power BI and DAX, PowerPoint.

## About the data

The dataset is public and historical, from Olist, a Brazilian marketplace. It covers 2016 to 2018, so the findings describe that period and not today's market.

Built by [Basit Ibrahim](https://basit890.github.io).
