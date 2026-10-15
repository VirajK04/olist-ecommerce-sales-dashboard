import sqlite3
import sys
import pandas as pd

if len(sys.argv) < 2:
    sys.exit("Usage: python3 scripts/run_sql.py sql/file.sql [outputs/file.csv]")

with open(sys.argv[1]) as f:
    query = f.read()

conn = sqlite3.connect("data/olist.db")
df = pd.read_sql_query(query, conn)
conn.close()

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)
print(df.to_string(index=False))

# Optional second argument: also save the result as a CSV
if len(sys.argv) > 2:
    df.to_csv(sys.argv[2], index=False)
    print(f"\nSaved {len(df)} rows to {sys.argv[2]}")
