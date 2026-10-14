import pandas as pd
from pathlib import Path

RAW = Path("data/raw")

# Loop over every CSV and print its size, column names and missing values
for f in sorted(RAW.glob("*.csv")):
    df = pd.read_csv(f)
    print("=" * 70)
    print(f.name, "| rows:", len(df), "| columns:", len(df.columns))
    print(list(df.columns))
    nulls = df.isna().sum()
    nulls = nulls[nulls > 0]
    print("Columns with missing values:", nulls.to_dict() if len(nulls) else "none")

# Extra look at the orders table: status values and the date range
orders = pd.read_csv(RAW / "olist_orders_dataset.csv")
print("=" * 70)
print("ORDER STATUS COUNTS")
print(orders["order_status"].value_counts())
print("First purchase:", orders["order_purchase_timestamp"].min())
print("Last purchase:", orders["order_purchase_timestamp"].max())
