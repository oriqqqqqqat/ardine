import os
from pathlib import Path
from datetime import datetime
from google import genai
import psycopg2
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_NAME = "models/gemini-2.5-flash"
SCHEMA_FILE = "./all_table_ardine.txt"

PROMPT_TEMPLATE = """You are a PostgreSQL expert.
Use ONLY the database schema provided below.
Write exactly ONE PostgreSQL query that answers the question.
Return SQL only.
Do not include explanations.
Do not include markdown fences.
Do not include comments.
Do not invent tables or columns that are not in the schema.
Use explicit JOIN syntax when appropriate.

Schema:
{schema_text}

Question: {question}
"""

QUESTIONS = [
"ผู้ใช้แต่ละคนอยู่ทีมไหนบ้าง",
"แต่ละทีมมีสมาชิกคนใดบ้าง และแต่ละคนมีบทบาทอะไร",
"ลูกค้าแต่ละรายอยู่ภายใต้ทีมใด",
"โปรเจกต์แต่ละอันเป็นของลูกค้ารายใด",
"ผู้ใช้แต่ละคนอยู่ในโปรเจกต์ใดบ้าง",
"งานแต่ละงานอยู่ในโปรเจกต์ใด และมีใครรับผิดชอบบ้าง",
"ใบแจ้งหนี้แต่ละใบเป็นของลูกค้ารายใดและอยู่ภายใต้ทีมใด",
"บันทึกเวลาทำงานแต่ละรายการเป็นของผู้ใช้คนใด ทำให้โปรเจกต์ใด และของลูกค้ารายใด",
"คำเชิญเข้าทีมแต่ละรายการเป็นของทีมใด และเชิญให้รับบทบาทอะไร",
"ลูกค้าแต่ละรายมีใบแจ้งหนี้ทั้งหมดกี่ใบ",
"แต่ละทีมมีสมาชิกทั้งหมดกี่คน",
"ลูกค้าแต่ละรายมีโปรเจกต์ทั้งหมดกี่อัน",
"โปรเจกต์ใดมีงานย่อยมากที่สุด",
"ผู้ใช้คนใดได้รับมอบหมายงานมากที่สุด",
"ผู้ใช้คนใดมีเวลางานรวมสูงที่สุด",
"ทีมใดมีชั่วโมงงานที่คิดเงินได้รวมมากที่สุด",
"ใบแจ้งหนี้ใดบ้างที่เลยกำหนดชำระแล้วยังไม่ได้จ่าย",
"คำเชิญเข้าทีมใดบ้างที่หมดอายุแล้วแต่ยังไม่ได้ตอบรับ",
"บันทึกเวลารายการใดบ้างที่ยังไม่ถูกนำไปออกบิล",
"โปรเจกต์ใดบ้างที่ตั้งงบแบบชั่วโมง และใช้เวลาไปแล้วเกินงบ",
"โปรเจกต์ใดบ้างที่ตั้งงบแบบจำนวนเงิน และมีมูลค่าเวลางานรวมเกินงบ",
"ผู้ใช้คนใดอยู่มากกว่าหนึ่งทีม",
"ผู้ใช้คนใดอยู่ในทีมแล้ว แต่ยังไม่ได้ถูกเพิ่มเข้าโปรเจกต์ใดเลย",
"งานใดบ้างที่ยังไม่มีผู้รับผิดชอบ",
"ลูกค้ารายใดมีมูลค่าใบแจ้งหนี้ที่จ่ายแล้วรวมสูงที่สุด",
"ผู้ใช้คนใดทำงานให้ลูกค้าหลากหลายรายมากที่สุด และลูกค้ารายใดที่ผู้ใช้นั้นใช้เวลาไปมากที่สุด",
"โปรเจกต์ใดมีสมาชิกน้อย แต่มีชั่วโมงงานรวมสูงที่สุด",
"ทีมใดมีชั่วโมงงานที่คิดเงินได้สูง แต่ยอดใบแจ้งหนี้ที่จ่ายแล้วรวมยังไม่สูงตาม",
"ลูกค้ารายใดมีเวลางานรวมมาก แต่ยังมีบันทึกเวลาที่ยังไม่ถูกนำไปออกบิลมากที่สุด",
"ผู้ใช้คนใดรับผิดชอบหลายงานในโปรเจกต์เดียวกัน และลงเวลารวมในโปรเจกต์นั้นมากกว่าค่าเฉลี่ยของสมาชิกคนอื่นในโปรเจกต์เดียวกัน"
]


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST"),
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        port=os.getenv("POSTGRES_PORT"),
    )


def load_schema_text():
    return Path(SCHEMA_FILE).read_text(encoding="utf-8")


def build_prompt(question: str, schema_text: str) -> str:
    return PROMPT_TEMPLATE.format(question=question, schema_text=schema_text)


def clean_sql(text: str) -> str:
    return text.strip().replace("```sql", "").replace("```", "").strip()


def ask(question: str):
    schema_text = load_schema_text()
    prompt = build_prompt(question, schema_text)

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt,
    )

    sql = clean_sql(response.text)

    usage = response.usage_metadata
    input_tokens = usage.prompt_token_count if usage else 0
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
        "question": question,
        "sql": sql,
        "result": result,
        "status": status,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "total_tokens": input_tokens + output_tokens,
    }


def save_results(results, output_file: str):
    lines = []
    lines.append("Text-to-SQL Results (Direct: full schema)")
    lines.append(f"Schema : {SCHEMA_FILE}")
    lines.append(f"Model  : {MODEL_NAME}")
    lines.append(f"Date   : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 60)

    total_tokens_all = 0

    for i, r in enumerate(results, 1):
        lines.append(f"\n[{i}] Q: {r['question']}")
        lines.append(f"    SQL:\n{r['sql']}")
        lines.append(f"    Result: {r['result']}")
        lines.append(f"    Status: {r['status']}")
        lines.append(
            f"    Tokens: total={r['total_tokens']}  input={r['input_tokens']}  output={r['output_tokens']}"
        )
        lines.append("-" * 60)
        total_tokens_all += r["total_tokens"]

    success = sum(1 for r in results if "✅" in r["status"])
    fail = len(results) - success

    lines.append("\nSummary")
    lines.append(f"  Total questions : {len(results)}")
    lines.append(f"  Success         : {success}")
    lines.append(f"  Failed          : {fail}")
    lines.append(f"  Accuracy        : {success / len(results) * 100:.1f}%")
    lines.append(f"  Total tokens    : {total_tokens_all}")
    lines.append(f"  Avg tokens/Q    : {total_tokens_all // len(results)}")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"\n📁 บันทึกแล้ว → {output_file}")


if __name__ == "__main__":
    all_results = []

    for q in QUESTIONS:
        result = ask(q)
        all_results.append(result)

        print(f"\nQ: {result['question']}")
        print(f"SQL: {result['sql']}")
        print(f"Result: {result['result']}")
        print(f"Status: {result['status']}")
        print(
            f"Tokens: {result['total_tokens']} (in: {result['input_tokens']}, out: {result['output_tokens']})"
        )
        print("-" * 60)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_results(all_results, f"results_direct_full_schema_{timestamp}.txt")
