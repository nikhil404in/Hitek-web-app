# ⚡ Hitek Instant Phone Search Engine (v4.0)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110%2B-009688.svg?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![DuckDB](https://img.shields.io/badge/DuckDB-1.0%2B-FFF000.svg?logo=duckdb&logoColor=black)](https://duckdb.org/)
[![Apache Parquet](https://img.shields.io/badge/Format-Apache%20Parquet-5082C7.svg)](https://parquet.apache.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
An ultra-high-performance, low-latency search engine and REST API designed to query **1.78 Billion+ records (~170 GB compressed Parquet / 480 GB raw JSON)** in **sub-second time**. Powered by DuckDB's in-memory columnar engine, asynchronous FastAPI, and a responsive web dashboard.
---
## 📑 Table of Contents
- [Overview](#-overview)
- [Architecture & Performance](#-architecture--performance)
- [Key Features](#-key-features)
- [Project Structure](#-project-structure)
- [Data Schema](#-data-schema)
- [Quick Start](#-quick-start)
  - [Kali Linux / Debian](#kali-linux--debian)
  - [Windows](#windows)
- [Configuration (.env)](#-configuration-env)
- [Data Ingestion & Parquet Importer](#-data-ingestion--parquet-importer)
- [API Reference](#-api-reference)
- [Web Interface](#-web-interface)
- [Logging & Monitoring](#-logging--monitoring)
- [Troubleshooting](#-troubleshooting)
---
## 🚀 Overview
Querying hundreds of millions or billions of rows typically requires resource-heavy clusters (like Elasticsearch or Spark). **Hitek Search Engine** solves this by pairing:
1. **Apache Parquet files** partitioned with Snappy compression and tight row groups.
2. **DuckDB SIMD vector query engine** executing parallel predicate pushdowns directly against parquet files with zero lock contention.
3. **Multi-threaded fan-out with early exit**, stopping disk scanning the moment required results are found.
4. **LRU in-memory cache** for sub-millisecond repeated lookups.
---
## ⚡ Architecture & Performance


                     ┌────────────────────────┐
                       │    Client / Web UI     │
                       └───────────┬────────────┘
                                   │ HTTP / REST
                                   ▼
                       ┌────────────────────────┐
                       │  FastAPI (Uvicorn)     │
                       │  - X-API-Key Auth      │
                       │  - Rate Limiting       │
                       │  - In-Memory LRU Cache │
                       └───────────┬────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
         [Cached? Return < 1ms]        [Cache Miss: Acquire Semaphore]
                                                  │
                                                  ▼
                                   ┌────────────────────────┐
                                   │ ThreadPoolExecutor     │
                                   │ (Parallel Worker Pool) │
                                   └───────────┬────────────┘
                                               │
                   ┌───────────────────────────┼───────────────────────────┐
                   ▼                           ▼                           ▼
        ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
        │ DuckDB Worker Thread │    │ DuckDB Worker Thread │    │ DuckDB Worker Thread │
        │   (File 000.parquet) │    │   (File 001.parquet) │    │   (File 156.parquet) │
        └──────────────────────┘    └──────────────────────┘    └──────────────────────┘
                   │                           │                           │
                   └───────────────────────────┼───────────────────────────┘
                                               │
                                 [Early-Exit Triggered]
                                               │
                                               ▼
                                   ┌────────────────────────┐
                                   │  JSON Response (< 1s)  │
                                   │  Logged to log.txt     │
                                   └────────────────────────┘


- **Query Latency:** Typically **100ms - 900ms** on cold queries across billions of records; **< 5ms** on cached queries.
- **Resource Efficient:** Thread-isolated DuckDB instances capped at 512MB RAM per worker, avoiding system memory exhaustion or swap thrashing.
- **Concurrency Protection:** Built-in semaphore prevents disk I/O saturations by limiting concurrent heavy scans with options to queue or reject (`429 Too Many Requests`).
---
## ✨ Key Features
- **Blazing Fast Searches:** Parallel file scanning with early termination once pagination limits are met.
- **Multi-Field Querying:** Search by `mobile`, `name`, `fname` (father's name), `address`, `alt` (alternate phone), `circle`, `doc_id`, or `all`.
- **Validation & Sanitization:** Strict 10-digit validation for mobile numbers (handles `+91`, `91`, whitespace, and dashes automatically).
- **Embedded Web UI (`/ui`):** Modern dark-mode dashboard with real-time health indicator, key storage, clean search cards, and tabular results.
- **Built-In Data Importer:** High-throughput streaming converter converting hundreds of gigabytes of raw JSON into snappy-compressed Parquet with DuckDB C++.
- **Audit Logging:** Logs timestamp, client IP, query term, search field, execution time, and response status to `log.txt`.
- **Production Ready:** Includes systemd / bash deployment scripts for Kali/Debian and batch files for Windows.
---
## 📂 Project Structure
```plaintext
.
├── api/
│   └── main.py              # Core FastAPI application, DuckDB parallel engine & endpoints
├── importer/
│   └── convert_to_parquet.py # C++ streaming JSON -> Parquet converter
├── parquet/                 # Directory holding partitioned .parquet files (0_0.parquet ...)
├── web/                     # Modern Web UI static files
│   ├── index.html           # Dashboard HTML interface
│   ├── style.css            # Dark mode styles & animations
│   └── app.js               # Frontend search logic, API key handling & UI state
├── .env.example             # Template configuration file
├── check_status.py          # Quick dataset verification & record count benchmark script
├── main.py                  # Root entrypoint
├── requirements.txt         # Python dependencies
├── setup_kali.sh            # Automated setup script for Kali Linux / Debian
├── start_api.bat            # One-click Windows launch script
└── start_api.sh             # One-click Linux launch script
🗃️ Data Schema
Each record contains the following columnar fields:

Field Name	Type	Description
oid	VARCHAR	Original MongoDB / Source Object ID
mobile	VARCHAR	Primary 10-digit mobile number
name	VARCHAR	Full subscriber / user name
fname	VARCHAR	Father's name / Guardian name
address	VARCHAR	Full residential or billing address
alt	VARCHAR	Alternate contact number
circle	VARCHAR	Telecom circle / state region
doc_id	VARCHAR	Identity document number (Aadhaar, Voter ID, PAN, etc.)
email	VARCHAR	Registered email address
🚀 Quick Start
Kali Linux / Debian
Clone the repository:

bash


git clone https://github.com/your-username/hitek-phone-search.git
cd hitek-phone-search
Run the automated setup script:

bash


chmod +x setup_kali.sh start_api.sh
./setup_kali.sh
Start the API:

bash


./start_api.sh
Open your browser:

Web UI: http://127.0.0.1:8000/ui
Interactive API Docs: http://127.0.0.1:8000/docs
Windows
Clone the repository and enter the directory:

cmd


git clone https://github.com/your-username/hitek-phone-search.git
cd hitek-phone-search
Create a virtual environment and install dependencies:

cmd


python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
Configure .env:

cmd


copy .env.example .env
Launch the server: Double-click start_api.bat or run:

cmd


python main.py
⚙️ Configuration (.env)
Create a .env file in the root directory:

ini


# API Security
API_KEY=hitek-search-2026-secret
# Server Binding
HOST=0.0.0.0
PORT=8000
# Concurrency & Protection
MAX_CONCURRENT_SEARCHES=2    # Max concurrent heavy disk scans
QUEUE_MODE=reject            # "reject" (instant 429) or "queue" (wait in line)
QUEUE_TIMEOUT=60.0           # Seconds to wait if QUEUE_MODE=queue
# SEARCH_TIMEOUT_SECONDS=30.0 # Leave empty for unlimited search duration
# Dataset Storage Paths
PARQUET_DIR=./parquet
JSON_PATH=./users_data.json
🔄 Data Ingestion & Parquet Importer
If you have a raw users_data.json file to convert into fast Parquet partitions:

Place your JSON file in the project folder or specify JSON_PATH in .env.

Run the streaming converter:

bash


python importer/convert_to_parquet.py
Features:

Streams directly via DuckDB C++ parser without loading the full file into memory.
Outputs optimized ~1 GB Snappy-compressed chunks.
Sets row-group sizes to 100,000 for high-efficiency skipping.
Verify your dataset and check query speeds:

bash


python check_status.py
📡 API Reference
All protected endpoints require the header:

http


X-API-Key: your_api_key_here
1. Health & Statistics
GET /health
Public health status check.

bash


curl http://127.0.0.1:8000/health
json


{
  "status": "ok",
  "engine": "DuckDB Parallel (8 workers) + Parquet",
  "total_records": 1782434387,
  "parquet_files": 157
}
GET /search/status
Public status endpoint indicating whether search slots are busy.

json


{
  "busy": false,
  "active_searches": 0,
  "max_concurrent": 2,
  "elapsed_seconds": 0.0,
  "waiting_in_queue": 0,
  "queue_mode": "reject"
}
2. Search Records
GET /search
Perform a multi-field or phone number search.

Parameters:

q (string, required): Search query (minimum 2 characters; exact 10 digits for mobile).
field (string, optional): mobile (default), name, fname, address, alt, circle, doc_id, or all.
page (int, optional): Page number (default: 1).
limit (int, optional): Number of records to return (default: 50, max: 100).
Example Request:

bash


curl -H "X-API-Key: hitek-search-2026-secret" \
     "http://127.0.0.1:8000/search?q=9876543210&field=mobile&limit=10"
Example Response:

json


{
  "query": "9876543210",
  "field": "mobile",
  "total": 1,
  "pages": 1,
  "total_pages": 1,
  "has_more": false,
  "page": 1,
  "limit": 10,
  "elapsed_ms": 284.5,
  "timed_out": false,
  "cached": false,
  "results": [
    {
      "oid": "648a1b2c3d4e5f6789012345",
      "mobile": "9876543210",
      "name": "JOHN DOE",
      "fname": "RICHARD DOE",
      "address": "123 MAIN STREET, SECTOR 4",
      "alt": "9123456780",
      "circle": "DELHI",
      "doc_id": "ABCDE1234F",
      "email": "john.doe@example.com"
    }
  ]
}
3. Direct Mobile Lookup
GET /record/{mobile}
Quick direct lookup for a 10-digit mobile number.

bash


curl -H "X-API-Key: hitek-search-2026-secret" \
     http://127.0.0.1:8000/record/9876543210
🖥️ Web Interface
The project includes a built-in static UI hosted at /ui.

API Key Persistence: Saved in browser localStorage for seamless reloads.
Live System Stats: Displays total dataset size and connection health in real time.
Copy & Export: Fast click-to-copy buttons for record fields.
Mobile Responsive: Works seamlessly on desktop, tablets, and phones.
📊 Logging & Monitoring
All incoming requests are written synchronously to log.txt:

plaintext


[2026-09-28 14:10:22] IP: 192.168.1.15    | FIELD: mobile  | QUERY: '9876543210'           | RESULTS: 1    | TIME:   184.2ms | STATUS: OK
[2026-09-28 14:11:05] IP: 192.168.1.20    | FIELD: mobile  | QUERY: '9876543210'           | RESULTS: 1    | TIME:     1.1ms | STATUS: OK (CACHED)
[2026-09-28 14:12:44] IP: 192.168.1.33    | FIELD: mobile  | QUERY: '9999999999'           | RESULTS: 0    | TIME:   412.0ms | STATUS: NOT FOUND
🛠️ Troubleshooting
1. Debian/Kali PEP 668 (externally-managed-environment)
If pip fails with an externally managed environment error on Kali Linux:

bash


# Recommended: Use a virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
# Alternative:
pip install -r requirements.txt --break-system-packages
2. Port 8000 Already in Use
The start scripts automatically terminate dangling processes on port 8000. If needed manually:

Linux: fuser -k 8000/tcp
Windows: netstat -ano | findstr :8000 then taskkill /F /PID <PID>
3. Too Many Requests (429 BUSY)
To allow more parallel searches at the expense of higher disk I/O, increase MAX_CONCURRENT_SEARCHES in .env:

ini


MAX_CONCURRENT_SEARCHES=4
Or switch to queue mode:

ini


QUEUE_MODE=queue
QUEUE_TIMEOUT=60.0
⚖️ Disclaimer & License
This project is licensed under the 
MIT License
.

Notice: This software is provided for database performance benchmarking, educational, and authorized administrative query purposes. Users are strictly responsible for complying with all applicable privacy, telecom, and data protection laws in their jurisdiction.
