from ollama import chat

response = chat(
    model="llama3.1:8b",
    messages=[
        {
            "role": "user",
            "content": "What is 2 + 2?",
        }
    ],
)

print(response.message.content)