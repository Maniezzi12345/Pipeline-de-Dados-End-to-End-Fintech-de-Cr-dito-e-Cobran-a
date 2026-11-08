import time
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client()
MODELO = "gemini-3.8-flash"

INSTRUCOES = """
Você é um agente de cobrança de uma fintech de crédito.
Responda em português, para um operador de cobrança.
Use somente os dados da tabela abaixo. Não invente números nem clientes.
Seja direto: no máximo 5 linhas.
Escreva valores em reais no formato R$ 1.234,56.
Termine com uma recomendação prática.
"""


def responder(pergunta, tabela, tentativas=3):
    dados = tabela.to_csv(index=False)
    prompt = f"{INSTRUCOES}\nPergunta: {pergunta}\n\nDados:\n{dados}"

    for tentativa in range(1, tentativas + 1):
        try:
            resposta = client.interactions.create(model=MODELO, input=prompt)
            return resposta.output_text
        except Exception as erro:
            if tentativa == tentativas:
                return f"⚠️ Não consegui falar com a IA agora ({erro}). Veja os dados abaixo."
            time.sleep(2 * tentativa)