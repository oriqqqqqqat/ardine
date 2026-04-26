import os
from datetime import datetime
from google import genai
import psycopg2
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv()

MODEL_NAME = "models/gemini-2.5-flash"
RAG_TOP_K = 5
EMBEDDING_MODEL_NAME = "intfloat/multilingual-e5-base"
SCHEMA_TABLE = "schema_ardine_short"

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

embedding_model = SentenceTransformer(EMBEDDING_MODEL_NAME)
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    port=os.getenv("POSTGRES_PORT"),
)
cur = conn.cursor()


def build_prompt(question: str, schema_text: str) -> str:
    return PROMPT_TEMPLATE.format(question=question, schema_text=schema_text)


def clean_sql(text: str) -> str:
    return text.strip().replace("```sql", "").replace("```", "").strip()


def retrieve(question: str, top_k: int = RAG_TOP_K):
    query_embedding = embedding_model.encode(f"query: {question}").tolist()

    cur.execute(
        f"""
        SELECT table_name, content
        FROM {SCHEMA_TABLE}
        ORDER BY embedding <=> %s::vector
        LIMIT %s
        """,
        (query_embedding, top_k),
    )

    return cur.fetchall()


def generate_sql(question: str):
    relevant_schemas = retrieve(question)

    print("📋 Retrieved tables:")
    for table_name, _ in relevant_schemas:
        print(f"   - {table_name}")

    context = "\n\n---\n\n".join([content for _, content in relevant_schemas])
    prompt = build_prompt(question, context)

    print("\n" + "─" * 60)
    print("📤 PROMPT ที่ส่งให้ LLM:")
    print("─" * 60)
    print(prompt)
    print("─" * 60 + "\n")

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt,
    )

    sql = clean_sql(response.text)

    usage = response.usage_metadata
    input_tokens = usage.prompt_token_count if usage else 0
    output_tokens = usage.candidates_token_count if usage else 0
    retrieved_tables = [t for t, _ in relevant_schemas]

    return sql, input_tokens, output_tokens, retrieved_tables


def save_results(results, output_file: str):
    lines = []
    lines.append("Text-to-SQL Results (RAG: retrieved schema)")
    lines.append(f"Schema source : {SCHEMA_TABLE} (pgvector)")
    lines.append(f"Top-k         : {RAG_TOP_K}")
    lines.append(f"Model         : {MODEL_NAME}")
    lines.append(f"Date          : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 60)

    total_tokens_all = 0

    for i, r in enumerate(results, 1):
        lines.append(f"\n[{i}] Q: {r['question']}")
        lines.append(f"    Retrieved: {', '.join(r['retrieved_tables'])}")
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

    for question in QUESTIONS:
        print("=" * 60)
        print(f"❓ Question : {question}\n")

        sql, input_tokens, output_tokens, retrieved_tables = generate_sql(question)
        total_tokens = input_tokens + output_tokens

        print(f"\n📄 SQL      :\n{sql}\n")

        try:
            cur.execute(sql)
            result = cur.fetchall()
            print(f"📊 Result   : {result}")
            print("🔖 Status   : ✅ Success")
            status = "✅ Success"
        except Exception as e:
            result = []
            conn.rollback()
            print("📊 Result   : []")
            print(f"🔖 Status   : ❌ Error: {e}")
            status = f"❌ Error: {e}"

        print(
            f"🔢 Tokens   : total={total_tokens}  input={input_tokens}  output={output_tokens}"
        )
        print("=" * 60)

        all_results.append(
            {
                "question": question,
                "retrieved_tables": retrieved_tables,
                "sql": sql,
                "result": result,
                "status": status,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "total_tokens": total_tokens,
            }
        )

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_results(all_results, f"results_rag_retrieved_schema_{timestamp}.txt")

    cur.close()
    conn.close()
