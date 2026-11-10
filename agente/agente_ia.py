import json
import time
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client()
MODELO = "gemini-3.5-flash-lite"
NIVEL_RACIOCINIO = "minimal"
CONFIG = {"thinking_config": {"thinking_level": NIVEL_RACIOCINIO}}

INSTRUCOES = """
Você é um agente de cobrança de uma fintech de crédito.
Responda em português, para um operador de cobrança.
Use somente os dados da tabela abaixo. Não invente números nem clientes.
Seja direto: no máximo 5 linhas.
Escreva valores em reais no formato R$ 1.234,56.
Termine com uma recomendação prática.
"""


def montar_prompt(pergunta, tabela):
    dados = tabela.to_csv(index=False)
    return f"{INSTRUCOES}\nPergunta: {pergunta}\n\nDados:\n{dados}"


def responder_stream(pergunta, tabela, tentativas=3):
    prompt = montar_prompt(pergunta, tabela)
    for tentativa in range(1, tentativas + 1):
        ja_escreveu = False
        try:

            for parte in client.models.generate_content_stream(model=MODELO, contents=prompt, config=CONFIG):
                if parte.text:
                    ja_escreveu = True
                    yield parte.text
            return
        except Exception as erro:
            if ja_escreveu or tentativa == tentativas:
                yield f"\n\n⚠️ Não consegui completar a resposta agora ({erro}). Veja os dados abaixo."
                return
            time.sleep(2 * tentativa)


def interpretar_grafico(pedido, dimensoes, medidas, tipos, tentativas=3):
    prompt = f"""
Você transforma pedidos de gráfico em escolhas fixas.
Pedido do usuário: "{pedido}"

Escolha UMA opção de cada lista, copiando o texto exatamente como está:
- dimensao (como agrupar): {list(dimensoes)}
- medida (o que medir): {list(medidas)}
- tipo (formato): {list(tipos)}

Use "Rosca" só se o pedido falar em proporção, participação, percentual ou pizza.
Se o pedido não tiver relação com nenhuma opção, devolva dimensao como null.
Responda apenas com JSON no formato:
{{"dimensao": "...", "medida": "...", "tipo": "..."}}
"""
    for tentativa in range(1, tentativas + 1):
        try:
            resposta = client.models.generate_content(
                model=MODELO,
                contents=prompt,

                config={**CONFIG, "response_mime_type": "application/json"},
            )
            escolha = json.loads(resposta.text)
            if (escolha.get("dimensao") in dimensoes
                    and escolha.get("medida") in medidas
                    and escolha.get("tipo") in tipos):
                return escolha
            return None
        except Exception:
            if tentativa == tentativas:
                return None
            time.sleep(2 * tentativa)