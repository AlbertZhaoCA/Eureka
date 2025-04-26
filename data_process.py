import json
import os
import pandas as pd
import json
import numpy as np

# 加载 parquet 文件
df = pd.read_parquet("39Krelease.parquet") #替换真实位置，同下

# 把所有 numpy 类型转为原生 Python 类型（如 list、float 等）
for col in df.columns:
    df[col] = df[col].map(lambda x: x.tolist() if isinstance(x, np.ndarray) else x)

# 保存为 jsonl
with open("39Krelease2.jsonl", "w", encoding="utf-8") as f:
    for record in df.to_dict(orient="records"):
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


current_dir = os.path.dirname(os.path.abspath(__file__))

with open("39Krelease2.jsonl", "r", encoding="utf-8") as input_file, open("39Krelease.jsonl", "w", encoding="utf-8") as output_file:
    for index, line in enumerate(input_file):
        data = json.loads(line)
        image = data["image"][0]
        image_path = os.path.join(current_dir, image) 
        image_url = f"file://{image_path.replace(os.sep, '/')}" 
        answer = data["answer"]
        question = data["question"]
       
        message_content = [
            {
                "role": "user",
                "content": [
                    {"type": "image", "image": image_url},
                    {"type": "text", "text": question}
                ]
            }
        ]
        
        message_content_str = json.dumps(message_content, ensure_ascii=False)
        
        formatted = {
            "id": str(index),
            "message": message_content_str,
            "answer": answer
        }

        json.dump(formatted, output_file, ensure_ascii=False)
        output_file.write("\n")