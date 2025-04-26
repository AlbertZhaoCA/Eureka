import json
import os

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

        # 写入文件
        json.dump(formatted, output_file, ensure_ascii=False)
        output_file.write("\n")
