"""
Olist processed-CSV profiler + KPI validator.

Usage:
    python3 profile_and_validate.py /path/to/data/processed

Requires: pandas  (pip install pandas)
Prints: schema/dtypes/nulls per table, key uniqueness and relationship
integrity, then recalculates every KPI from the Power BI brief and
compares it with the verified target. Nothing is modified or written.
"""
import sys
from pathlib import Path
import pandas as pd

folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
FILES = ["customers", "orders", "order_items", "payments", "reviews",
         "products", "sellers", "geolocation", "category_translation"]

def load(name):
    p = folder / f"{name}_cleaned.csv"
    if not p.exists():
        print(f"!! missing {p}")
        return None
    return pd.read_csv(p)

T = {n: load(n) for n in FILES}
print("\n=== 1. SCHEMA ===")
for n, df in T.items():
    if df is None:
        continue
    print(f"\n[{n}] rows={len(df):,} cols={df.shape[1]}")
    info = pd.DataFrame({"dtype": df.dtypes.astype(str),
                         "nulls": df.isna().sum(),
                         "distinct": df.nunique()})
    print(info.to_string())

cu, o, oi, pay, rv, pr, se = (T[k] for k in
    ["customers", "orders", "order_items", "payments", "reviews", "products", "sellers"])
if any(x is None for x in (cu, o, oi, pay, rv, pr, se)):
    sys.exit("Cannot continue: a core table is missing.")

print("\n=== 2. KEYS & RELATIONSHIPS ===")
def uniq(df, col, label):
    print(f"{label}: unique={df[col].is_unique}  dupes={df[col].duplicated().sum():,}")
uniq(cu, "customer_id", "customers[customer_id]")
uniq(o, "order_id", "orders[order_id]")
uniq(pr, "product_id", "products[product_id]")
uniq(se, "seller_id", "sellers[seller_id]")
def orphans(child, ccol, parent, pcol, label):
    n = (~child[ccol].isin(parent[pcol])).sum()
    print(f"{label}: orphan child rows={n:,}")
orphans(o, "customer_id", cu, "customer_id", "orders -> customers")
orphans(oi, "order_id", o, "order_id", "order_items -> orders")
orphans(pay, "order_id", o, "order_id", "payments -> orders")
orphans(rv, "order_id", o, "order_id", "reviews -> orders")
orphans(oi, "product_id", pr, "product_id", "order_items -> products")
orphans(oi, "seller_id", se, "seller_id", "order_items -> sellers")
print(f"reviews per order >1: {(rv.groupby('order_id').size() > 1).sum():,} orders "
      f"(many-side; use reviews as a fact table, not a dimension)")

print("\n=== 3. KPI VALIDATION (recalculated vs brief) ===")
for c in ["order_purchase_timestamp", "order_delivered_customer_date",
          "order_estimated_delivery_date"]:
    o[c] = pd.to_datetime(o[c], errors="coerce")
deliv = o[o.order_status == "delivered"]
d_ids = set(deliv.order_id)
oi_d = oi[oi.order_id.isin(d_ids)]

rows = []
def chk(name, got, target, tol=0.01):
    ok = abs(got - target) <= tol * max(1, abs(target)) if target else got == target
    rows.append((name, got, target, "OK" if ok else "CHECK"))

total_orders = o.order_id.nunique()
delivered_orders = deliv.order_id.nunique()
prod_rev = oi_d.price.sum()
freight = oi_d.freight_value.sum()
chk("Total orders", total_orders, 99441, 0)
chk("Delivered orders", delivered_orders, 96478, 0)
chk("Completion rate %", 100 * delivered_orders / total_orders, 97.02, 0.001)
chk("Product revenue (R$)", prod_rev, 13.22e6, 0.005)
chk("Freight (R$)", freight, 2.20e6, 0.01)
chk("Delivered GMV (R$)", prod_rev + freight, 15.42e6, 0.005)
chk("AOV excl. freight (R$)", prod_rev / delivered_orders, 137.04, 0.001)
chk("Recorded payments, delivered (R$)",
    pay[pay.order_id.isin(d_ids)].payment_value.sum(), 15.42e6, 0.005)

cd = deliv.merge(cu[["customer_id", "customer_unique_id"]], on="customer_id")
per_cust = cd.groupby("customer_unique_id").order_id.nunique()
chk("Unique customers (delivered)", len(per_cust), 93358, 0)
chk("Repeat customers", (per_cust > 1).sum(), 2801, 0)
chk("Repeat rate %", 100 * (per_cust > 1).mean(), 3.00, 0.01)

cat_col = "product_category_name_english"
if cat_col in pr.columns:
    top = (oi_d.merge(pr[["product_id", cat_col]], on="product_id")
           .groupby(cat_col).price.sum().sort_values(ascending=False).head(5))
    print("\nTop 5 categories by delivered product revenue:")
    print(top.round(2).to_string())

sel = oi_d.groupby("seller_id").price.sum().sort_values(ascending=False)
chk("Registered sellers", se.seller_id.nunique(), 3095, 0)
chk("Sellers with delivered sales", len(sel), 2970, 0)
chk("Top seller revenue (R$)", sel.iloc[0], 226987.93, 0.001)
chk("Top-10 seller share %", 100 * sel.head(10).sum() / sel.sum(), 13.27, 0.01)

v = deliv.dropna(subset=["order_delivered_customer_date",
                         "order_estimated_delivery_date",
                         "order_purchase_timestamp"]).copy()
v["days"] = (v.order_delivered_customer_date - v.order_purchase_timestamp).dt.total_seconds() / 86400
# the estimated date is date-only in this dataset; compare on calendar dates
dd = v.order_delivered_customer_date.dt.normalize()
ed = v.order_estimated_delivery_date.dt.normalize()
v["status"] = "On Time"
v.loc[dd < ed, "status"] = "Early"
v.loc[dd > ed, "status"] = "Late"
chk("Valid delivery comparisons", len(v), 96470, 0)
chk("Avg delivery days", v.days.mean(), 12.56, 0.005)
chk("Late orders", (v.status == "Late").sum(), 6534, 0)
chk("Late rate %", 100 * (v.status == "Late").mean(), 6.77, 0.01)
print("\nDelivery status mix %:")
print((100 * v.status.value_counts(normalize=True)).round(2).to_string())

chk("Review records", len(rv), 99224, 0)
chk("Avg review score", rv.review_score.mean(), 4.09, 0.005)
pos = 100 * (rv.review_score >= 4).mean()
neu = 100 * (rv.review_score == 3).mean()
neg = 100 * (rv.review_score <= 2).mean()
chk("Positive reviews %", pos, 77.07, 0.005)
chk("Neutral reviews %", neu, 8.24, 0.01)
chk("Negative reviews %", neg, 14.69, 0.005)

# NOTE: how reviews map to orders matters (multi-review orders). Report both.
by_status = rv.merge(v[["order_id", "status"]], on="order_id")
print("\nAvg review score by delivery status (all review rows):")
print(by_status.groupby("status").review_score.mean().round(2).to_string())
print("Same, using one score per order (mean of that order's reviews):")
one = by_status.groupby(["order_id", "status"]).review_score.mean().reset_index()
print(one.groupby("status").review_score.mean().round(2).to_string())

print("\n" + pd.DataFrame(rows, columns=["metric", "recalculated", "target", "result"])
      .to_string(index=False, float_format=lambda x: f"{x:,.2f}"))

print("\n=== 4. DATA-QUALITY CHECKS ===")
pt = pay.groupby("order_id").payment_value.sum()
it = (oi.groupby("order_id").price.sum() + oi.groupby("order_id").freight_value.sum())
cmp_ = pd.concat([pt.rename("paid"), it.rename("items")], axis=1)
cmp_["diff"] = (cmp_.paid - cmp_.items).round(2)
print("payment > items+freight:", int((cmp_["diff"] > 0.01).sum()), "(brief: 291)")
print("payment < items+freight:", int((cmp_["diff"] < -0.01).sum()), "(brief: 90)")
print("delivered orders with no payment:", len(d_ids - set(pay.order_id)), "(brief: 1)")
print("delivered orders missing delivery/estimate dates:",
      len(deliv) - len(v), "(brief: 8)")
if "product_weight_g" in pr.columns:
    print("product_weight_g nulls:", int(pr.product_weight_g.isna().sum()))
print("\nDate range:", o.order_purchase_timestamp.min(), "->", o.order_purchase_timestamp.max())
print("Orders by month (check partial months):")
print(o.groupby(o.order_purchase_timestamp.dt.to_period("M")).size().to_string())
