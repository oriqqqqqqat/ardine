import os
from pathlib import Path
from datetime import datetime
from google import genai
import psycopg2
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_NAME = "models/gemini-2.5-flash-lite"


def get_db_connection():
    return psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    port=os.getenv("POSTGRES_PORT")
    )


def load_schema_text():
    return Path("./all_table_ardine.txt").read_text(encoding="utf-8")


def ask(question):
    schema_text = load_schema_text()

    prompt = f"""
You are a PostgreSQL expert. Given this Northwind database schema:

{schema_text}

Write a PostgreSQL query ONLY.
No explanation.
No markdown.
Question: {question}
"""

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt
    )

    sql = response.text.strip().replace("```sql", "").replace("```", "").strip()

    usage = response.usage_metadata
    input_tokens  = usage.prompt_token_count     if usage else 0
    output_tokens = usage.candidates_token_count if usage else 0

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(sql)
        result = cur.fetchall()
        cur.close()
        conn.close()
        status = "✅ Success"
    except Exception as e:
        result = []
        status = f"❌ Error: {e}"

    return {
        "question"     : question,
        "sql"          : sql,
        "result"       : result,
        "status"       : status,
        "input_tokens" : input_tokens,
        "output_tokens": output_tokens,
        "total_tokens" : input_tokens + output_tokens
    }


def save_results(results, output_file):
    lines = []
    lines.append(f"Text-to-SQL Results")
    lines.append(f"Schema: all_tables.txt")
    lines.append(f"Model : {MODEL_NAME}")
    lines.append(f"Date  : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 60)

    total_tokens_all = 0

    for i, r in enumerate(results, 1):
        lines.append(f"\n[{i}] Q: {r['question']}")
        lines.append(f"    SQL:\n{r['sql']}")
        lines.append(f"    Result: {r['result']}")
        lines.append(f"    Status: {r['status']}")
        lines.append(f"    Tokens: total={r['total_tokens']}  input={r['input_tokens']}  output={r['output_tokens']}")
        lines.append("-" * 60)
        total_tokens_all += r["total_tokens"]

    success = sum(1 for r in results if "✅" in r["status"])
    fail    = len(results) - success

    lines.append(f"\nSummary")
    lines.append(f"  Total questions : {len(results)}")
    lines.append(f"  Success         : {success}")
    lines.append(f"  Failed          : {fail}")
    lines.append(f"  Accuracy        : {success/len(results)*100:.1f}%")
    lines.append(f"  Total tokens    : {total_tokens_all}")
    lines.append(f"  Avg tokens/Q    : {total_tokens_all//len(results)}")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"\n📁 บันทึกแล้ว → {output_file}")


if __name__ == "__main__":
    questions = [
"ลูกค้าแต่ละรายมีโปรเจกต์อยู่กี่อัน",
"invoice ไหนบ้างที่เลย due date แล้วแต่ยังไม่ได้จ่าย มีค้างอยู่กี่วันแล้ว",
"มีใครบ้างที่อยู่มากกว่าหนึ่งทีม แล้วในแต่ละทีมได้ role อะไรบ้าง",
"โปรเจกต์ไหนมีสมาชิกในโปรเจกต์มากที่สุด แล้วสมาชิกพวกนั้นมีใครบ้าง",
"มีใครบ้างที่อยู่ในทีมแล้ว แต่ยังไม่ได้ถูกเพิ่มเข้าโปรเจกต์ไหนเลย",
"คนไหนบันทึกเวลาทำงานรวมมากที่สุดใน 30 วันที่ผ่านมา แล้วส่วนใหญ่ทำงานให้ลูกค้าคนไหน",
"มีผู้ใช้คนไหนบ้างที่ใช้อีเมลลงท้ายด้วย @kmitl.ac.th",
"ถ้าดูแยกเป็นทีม ทีมไหนมีชั่วโมงงานที่คิดเงินได้รวมเยอะที่สุด",
"โปรเจกต์ไหนมีการบันทึกเวลาเยอะ แต่จำนวนสมาชิกในโปรเจกต์น้อย",
"มีใครบ้างที่รับผิดชอบงานหลายอย่างในโปรเจกต์เดียวกัน มีงานอะไรบ้าง",
"มีใครบ้างที่อยู่หลายทีม แต่มีการลงเวลาอยู่แค่ทีมเดียว",
"ตอนนี้แต่ละทีมมี owner กับ admin เป็นใครบ้าง",
"คนที่ใช้อีเมล @kmitl.ac.th อยู่ในทีมไหนบ้าง และในแต่ละทีมมี role อะไร"
    ]

    all_results = []

    for q in questions:
        result = ask(q)
        all_results.append(result)

        print(f"\nQ: {result['question']}")
        print(f"SQL: {result['sql']}")
        print(f"Result: {result['result']}")
        print(f"Status: {result['status']}")
        print(f"Tokens: {result['total_tokens']} (in: {result['input_tokens']}, out: {result['output_tokens']})")
        print("-" * 60)

    # บันทึกผลลัพธ์ทั้งหมดลงไฟล์
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_results(all_results, f"results_all_tables_{timestamp}.txt")