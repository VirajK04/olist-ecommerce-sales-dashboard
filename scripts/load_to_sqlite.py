import sqlite3
import pandas as pd
from pathlib import Path

RAW = Path("data/raw")
DB = Path("data/olist.db")

TABLES = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_products_dataset.csv": "products",
    "olist_customers_dataset.csv": "customers",
    "olist_order_payments_dataset.csv": "payments",
    "product_category_name_translation.csv": "category_translation",
}

DB.unlink(missing_ok=True)
conn = sqlite3.connect(DB)

for csv_name, table in TABLES.items():
    df = pd.read_csv(RAW / csv_name)
    df.to_sql(table, conn, index=False)
    print(f"{table:22s} loaded {len(df):>7,} rows")

conn.executescript("""
CREATE INDEX idx_orders_id       ON orders(order_id);
CREATE INDEX idx_orders_cust     ON orders(customer_id);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);
CREATE INDEX idx_products_id     ON products(product_id);
CREATE INDEX idx_customers_id    ON customers(customer_id);
""")
conn.commit()

print("\nVerification (read back from SQLite):")
for table in TABLES.values():
    n = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    print(f"{table:22s} {n:>7,} rows")
conn.close()
