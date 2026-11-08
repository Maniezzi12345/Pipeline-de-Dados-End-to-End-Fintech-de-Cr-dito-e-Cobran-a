from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client()

resposta = client.interactions.create(
    model="gemini-3.8-flash",
    input="Em uma frase, o que é um agente de cobrança?"
)

print(resposta.output_text)