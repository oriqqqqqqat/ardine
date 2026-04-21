from sentence_transformers import SentenceTransformer
import psycopg2
from google import genai
from dotenv import load_dotenv
from datetime import datetime
import os

load_dotenv()

model = SentenceTransformer('intfloat/multilingual-e5-base')

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    port=os.getenv("POSTGRES_PORT")
)

cur = conn.cursor()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_NAME = "models/gemini-2.5-flash-lite"


def retrieve(question, top_k=6):
    query_embedding = model.encode(f"query: {question}").tolist()

    cur.execute("""
        SELECT table_name, content
        FROM schema_ardine_short
        ORDER BY embedding <=> %s::vector
        LIMIT %s
    """, (query_embedding, top_k))

    return cur.fetchall()


def generate_sql(question):
    relevant_schemas = retrieve(question)

    print("📋 Retrieved tables:")
    for table_name, _ in relevant_schemas:
        print(f"   - {table_name}")

    context = "\n\n---\n\n".join([content for _, content in relevant_schemas])

    prompt = f"""You are a Text-to-SQL assistant for a PostgreSQL database.
Use only the schema provided to generate SQL.
Return only the SQL query, no explanation.

Schema:
{context}

Question: {question}"""

    print("\n" + "─" * 60)
    print("📤 PROMPT ที่ส่งให้ LLM:")
    print("─" * 60)
    print(prompt)
    print("─" * 60 + "\n")

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt
    )

    sql = response.text.strip()
    sql = sql.replace("```sql", "").replace("```", "").strip()

    usage = response.usage_metadata
    input_tokens  = usage.prompt_token_count     if usage else 0
    output_tokens = usage.candidates_token_count if usage else 0

    retrieved_tables = [t for t, _ in relevant_schemas]

    return sql, input_tokens, output_tokens, retrieved_tables


def save_results(results, output_file):
    lines = []
    lines.append(f"Text-to-SQL Results (RAG)")
    lines.append(f"Schema : schema_ardine_short (pgvector)")
    lines.append(f"Model  : {MODEL_NAME}")
    lines.append(f"Date   : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 60)

    total_tokens_all = 0

    for i, r in enumerate(results, 1):
        lines.append(f"\n[{i}] Q: {r['question']}")
        lines.append(f"    Retrieved: {', '.join(r['retrieved_tables'])}")
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
    lines.append(f"  Accuracy        : {success / len(results) * 100:.1f}%")
    lines.append(f"  Total tokens    : {total_tokens_all}")
    lines.append(f"  Avg tokens/Q    : {total_tokens_all // len(results)}")

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

    for question in questions:
        print("=" * 60)
        print(f"❓ Question : {question}\n")

        sql, input_tokens, output_tokens, retrieved_tables = generate_sql(question)
        total_tokens = input_tokens + output_tokens

        print(f"\n📄 SQL      :\n{sql}\n")

        try:
            cur.execute(sql)
            result = cur.fetchall()
            print(f"📊 Result   : {result}")
            print(f"🔖 Status   : ✅ Success")
            status = "✅ Success"
        except Exception as e:
            result = []
            conn.rollback()  # ล้าง transaction ที่พังออก ให้ query ถัดไปรันได้
            print(f"📊 Result   : []")
            print(f"🔖 Status   : ❌ Error: {e}")
            status = f"❌ Error: {e}"

        print(f"🔢 Tokens   : total={total_tokens}  "
              f"input={input_tokens}  "
              f"output={output_tokens}")
        print("=" * 60)

        all_results.append({
            "question"        : question,
            "retrieved_tables": retrieved_tables,
            "sql"             : sql,
            "result"          : result,
            "status"          : status,
            "input_tokens"    : input_tokens,
            "output_tokens"   : output_tokens,
            "total_tokens"    : total_tokens
        })

    # บันทึกผลลัพธ์ทั้งหมด
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_results(all_results, f"results_rag_{timestamp}.txt")

    cur.close()
    conn.close()