#!/usr/bin/env python3
import os
import glob
import time
import duckdb
from dotenv import load_dotenv

_default_parquet = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parquet")
PARQUET_DIR = os.environ.get("PARQUET_DIR") or (_default_parquet if os.path.exists(_default_parquet) else (r"D:/parquet" if os.path.exists(r"D:/parquet") else _default_parquet))
PARQUET_DIR = PARQUET_DIR.replace("\\", "/")

def is_valid_parquet(filepath):
    try:
        if os.path.getsize(filepath) < 1000:
            return False
        with open(filepath, "rb") as f:
            f.seek(-4, os.SEEK_END)
            return f.read(4) == b"PAR1"
    except Exception:
        return False

raw_files = glob.glob(f"{PARQUET_DIR}/*.parquet")
valid_files = [f.replace("\\", "/") for f in sorted(raw_files) if is_valid_parquet(f)]

print("=" * 60)
print("             PARQUET DATASET STATUS")
print("=" * 60)
print(f"Parquet Folder : {PARQUET_DIR}")
print(f"Completed Files: {len(valid_files)} / {len(raw_files)}")

if not valid_files:
    print("Converting initial files... Please run start_importer.bat if not running.")
else:
    total_size = sum(os.path.getsize(f) for f in valid_files)
    print(f"Total Ready Size : {total_size / 1e9:.2f} GB")
    
    file_list_sql = ", ".join(f"'{f}'" for f in valid_files)
    src = f"read_parquet([{file_list_sql}])"
    
    con = duckdb.connect()
    t0 = time.time()
    count = con.execute(f"SELECT COUNT(*) FROM {src}").fetchone()[0]
    elapsed = (time.time() - t0) * 1000
    print(f"Total Ready Rows : {count:,} records  (counted in {elapsed:.1f} ms)")
    
    print("\nSample Records:")
    rows = con.execute(f"SELECT mobile, name, email, doc_id, circle FROM {src} LIMIT 3").fetchall()
    for r in rows:
        print(" ", r)
    con.close()
print("=" * 60)
