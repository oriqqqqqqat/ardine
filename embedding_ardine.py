import os
import json
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('intfloat/multilingual-e5-base')

txt_folder = "./schema_ardine_short"  # โฟลเดอร์ที่เก็บไฟล์ txt
output_file = "./embeddings_ardine.json"

results = []

for filename in sorted(os.listdir(txt_folder)):
    if not filename.endswith(".txt"):
        continue

    table_name = filename.replace(".txt", "")

    with open(os.path.join(txt_folder, filename), "r", encoding="utf-8") as f:
        content = f.read()

    # multilingual-e5 ต้องใส่ prefix "passage: " ตอน embed document
    embedding = model.encode(f"passage: {content}").tolist()

    results.append({
        "table_name": table_name,
        "content": content,
        "embedding_dimensions": len(embedding),
        "embedding_preview": embedding[:5],  # แสดงแค่ 5 ค่าแรก
        "embedding": embedding               # vector เต็ม 768 dimensions
    })

    print(f"✓ {table_name:30s} | dims: {len(embedding)} | preview: {[round(v, 4) for v in embedding[:3]]}")

with open(output_file, "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"\nบันทึกแล้ว → {output_file}")
print(f"จำนวนตาราง: {len(results)}")