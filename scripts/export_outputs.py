import sqlite3
import pandas as pd
from pathlib import Path

OUT = Path("outputs")
OUT.mkdir(exist_ok=True)

# SQL file -> CSV file
EXPORTS = {
    "sql/01_total_revenue.sql":              "total_revenue.csv",
    "sql/02b_monthly_revenue_dashboard.sql": "monthly_revenue_mom.csv",
    "sql/03_top_categories.sql":             "top_categories.csv",
    "sql/04_orders_by_state.sql":            "orders_by_state.csv",
    "sql/05_delivery_time.sql":              "delivery_overall.csv",
    "sql/05b_delivery_by_state.sql":         "delivery_by_state.csv",
    "sql/06_average_order_value.sql":        "average_order_value.csv",
    "sql/07_sales_detail.sql":               "sales_detail.csv",
}

conn = sqlite3.connect("data/olist.db")
for sql_file, csv_name in EXPORTS.items():
    df = pd.read_sql_query(Path(sql_file).read_text(), conn)
    df.to_csv(OUT / csv_name, index=False)
    print(f"{csv_name:26s} {len(df):>8,} rows")
conn.close()

# Checks, read back from the exported detail file
d = pd.read_csv(OUT / "sales_detail.csv")
order_values = d.groupby("order_id")["price"].sum()
print("\nCHECKS ON sales_detail.csv")
print("item rows:        ", len(d))
print("distinct orders:  ", d["order_id"].nunique())
print("total revenue:    ", round(d["price"].sum(), 2))
print("average order:    ", round(order_values.mean(), 2))
print("MEDIAN order:     ", round(order_values.median(), 2))
print("\nRevenue by region:")
print(d.groupby("region")["price"].sum().round(2).sort_values(ascending=False).to_string())
