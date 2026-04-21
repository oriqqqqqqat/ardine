import json
import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

# ===== config =====
DB_CONFIG = {
    "host":     os.getenv("POSTGRES_HOST"),
    "dbname":   os.getenv("POSTGRES_DB"),
    "user":     os.getenv("POSTGRES_USER"),
    "password": os.getenv("POSTGRES_PASSWORD"),
    "port":     os.getenv("POSTGRES_PORT", 5432)
}
EMBEDDINGS_FILE = "./embeddings_ardine.json"
# ==================

conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

# สร้าง extension และตาราง ถ้ายังไม่มี
cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
cur.execute("""
    CREATE TABLE IF NOT EXISTS schema_ardine_short (
        id         SERIAL PRIMARY KEY,
        table_name VARCHAR(50),
        content    TEXT,
        embedding  vector(768)
    );
""")
conn.commit()

# โหลด embeddings จากไฟล์ JSON
with open(EMBEDDINGS_FILE, "r", encoding="utf-8") as f:
    records = json.load(f)

# insert ทีละ record
for record in records:
    cur.execute(
        """
        INSERT INTO schema_ardine_short (table_name, content, embedding)
        VALUES (%s, %s, %s)
        """,
        (
            record["table_name"],
            record["content"],
            record["embedding"]
        )
    )
    print(f"✓ inserted: {record['table_name']}")

conn.commit()
cur.close()
conn.close()

print(f"\nเสร็จแล้ว — insert {len(records)} ตาราง")