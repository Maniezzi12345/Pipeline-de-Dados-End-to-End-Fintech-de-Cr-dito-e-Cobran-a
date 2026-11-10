import time
from datetime import datetime
from zoneinfo import ZoneInfo

import streamlit as st
from banco import consultar, buscar_resumo, buscar_contexto, buscar_grafico, DIMENSOES, MEDIDAS
from agente_ia import responder_stream
from grafico import grafico_barras
from perguntas import PERGUNTAS

DATA_BASE = "22/10/2026"
NOME_USUARIO = "João"

SUGESTOES = [
    ("📋", "Quem cobrar primeiro?", "Os 10 clientes com maior prioridade", "Prioridade", "Quem devo cobrar primeiro hoje?"),
    ("📊", "Atraso por faixa de risco", "Onde está o maior risco da carteira", "Faixa de risco", "Quanto temos em atraso por faixa de risco?"),
    ("⚠️", "Promessas quebradas", "Clientes que não pagaram o prometido", "Promessas", "Quais clientes quebraram promessa?"),
    ("⏸️", "Quem pausar?", "Excesso de contato nos últimos 7 dias", "Pausar", "Quem devo pausar por excesso de contato?"),
]

st.set_page_config(page_title="Agente de Cobrança", page_icon="💼", layout="wide")

st.markdown("""
<style>
    footer {visibility: hidden;}
    .block-container {padding-top: 1.5rem; max-width: 860px;}
    .saudacao {text-align: center; margin-top: 4vh;}
    .saudacao .icone {display: inline-grid; place-items: center; width: 52px; height: 52px;
        border-radius: 14px; background: #111827; color: #fff; font-size: 24px; margin-bottom: 14px;}
    .saudacao h1 {font-size: 2rem; font-weight: 600; margin: 0; padding: 0;}
    .saudacao p {opacity: 0.65; margin-top: 6px;}
    .stat {border: 1px solid rgba(128,128,128,0.25); border-radius: 12px; padding: 10px 16px;}
    .stat small {opacity: 0.65; display: block; font-size: 0.8rem;}
    .stat b {font-size: 1.35rem;}
    .st-key-sugestoes .stButton button {
        text-align: left; justify-content: flex-start; border-radius: 14px; min-height: 76px;
        padding: 12px 16px; white-space: normal;}
    .st-key-chips .stButton button {min-height: 0 !important; border-radius: 999px !important; padding: 4px 14px !important;}
    .aviso {text-align: center; font-size: 0.75rem; opacity: 0.55; margin-top: 8px;}
    .pensando {display: flex; align-items: center; gap: 5px; opacity: 0.7; font-size: 0.95rem;}
    .pensando span {width: 7px; height: 7px; border-radius: 50%; background: currentColor;
        animation: pulso 1.2s infinite ease-in-out;}
    .pensando span:nth-child(2) {animation-delay: 0.15s;}
    .pensando span:nth-child(3) {animation-delay: 0.3s; margin-right: 6px;}
    @keyframes pulso {0%, 80%, 100% {opacity: 0.2; transform: scale(0.8);} 40% {opacity: 1; transform: scale(1);}}
    .passo {display: inline-block; font-size: 0.8rem; opacity: 0.75; border: 1px solid rgba(128,128,128,0.3);
        border-radius: 8px; padding: 3px 10px; margin-bottom: 8px;}
    .resumo {display: flex; justify-content: space-between; font-size: 0.9rem; padding: 2px 0;}
</style>
""", unsafe_allow_html=True)

ROTULOS = {
    "posicao_fila": st.column_config.NumberColumn("Posição"),
    "cliente_id": st.column_config.NumberColumn("Cliente", format="%d"),
    "primeiro_nome": "Nome",
    "faixa_risco": "Risco",
    "valor_em_atraso": st.column_config.NumberColumn("Valor em atraso", format="R$ %.2f"),
    "valor_total": st.column_config.NumberColumn("Valor total", format="R$ %.2f"),
    "dias_atraso_mais_antigo": st.column_config.NumberColumn("Dias de atraso"),
    "score_prioridade": st.column_config.ProgressColumn("Prioridade", min_value=0, max_value=100, format="%.0f"),
    "acao_sugerida": "Ação sugerida",
    "clientes": st.column_config.NumberColumn("Clientes"),
    "qtd_contatos_ultimos_7_dias": st.column_config.NumberColumn("Contatos (7 dias)"),
}


def formatar_reais(valor):
    if valor >= 1_000_000:
        return f"R$ {valor / 1_000_000:.2f} mi".replace(".", ",")
    texto = f"R$ {valor:,.2f}"
    return texto.replace(",", "X").replace(".", ",").replace("X", ".")


def saudacao():
    hora = datetime.now(ZoneInfo("America/Sao_Paulo")).hour
    if hora < 12:
        return "Bom dia"
    if hora < 18:
        return "Boa tarde"
    return "Boa noite"


@st.cache_data(ttl=3600, show_spinner=False)
def resumo_em_cache():
    return buscar_resumo()


@st.cache_data(ttl=3600, show_spinner=False)
def consultar_em_cache(sql):
    return consultar(sql)


def perguntar(pergunta, sql=None):
    inicio = time.perf_counter()
    tabela = consultar_em_cache(sql) if sql else buscar_contexto()
    duracao = time.perf_counter() - inicio
    st.session_state.historico.append(
        {"pergunta": pergunta, "tabela": tabela, "texto": None, "duracao": duracao}
    )


def escrever_resposta(item):
    chave = (item["pergunta"], item["tabela"].to_csv(index=False))
    respostas = st.session_state.respostas
    if chave in respostas:
        item["texto"] = respostas[chave]
        st.markdown(item["texto"])
        return
    with st.empty():
        st.markdown('<div class="pensando"><span></span><span></span><span></span> Pensando...</div>',
                    unsafe_allow_html=True)
        partes = responder_stream(item["pergunta"], item["tabela"])
        primeira = next(partes, "")
        texto = st.write_stream(_juntar(primeira, partes))
    item["texto"] = texto
    respostas[chave] = texto


def _juntar(primeira, resto):
    yield primeira
    yield from resto


if "historico" not in st.session_state:
    st.session_state.historico = []
if "respostas" not in st.session_state:
    st.session_state.respostas = {}

resumo = resumo_em_cache()
valor_em_atraso = formatar_reais(float(resumo["valor_em_atraso"]))

# ---------- menu lateral ----------
with st.sidebar:
    st.markdown("### 💼 Agente de Cobrança")
    st.caption("Fintech · camada gold")
    pagina = st.radio("Navegação", ["💬 Agente", "📊 Gráficos"], label_visibility="collapsed")
    if pagina == "💬 Agente" and st.button("＋ Nova conversa", width="stretch"):
        st.session_state.historico = []
        st.rerun()
    st.divider()
    st.caption("RESUMO DO DIA")
    st.markdown(f"""
        <div class="resumo"><span>Valor em atraso</span><b>{valor_em_atraso}</b></div>
        <div class="resumo"><span>Clientes na fila</span><b>{int(resumo["clientes"])}</b></div>
        <div class="resumo"><span>Para ligar</span><b>{int(resumo["ligar"])}</b></div>
        <div class="resumo"><span>Aguardando promessa</span><b>{int(resumo["aguardando"])}</b></div>
    """, unsafe_allow_html=True)
    st.divider()
    st.caption(f"🟢 Dados até {DATA_BASE}")


def pagina_agente():
    # ---------- tela inicial ----------
    if not st.session_state.historico:
        st.markdown(f"""
            <div class="saudacao">
                <div class="icone">✦</div>
                <h1>{saudacao()}, {NOME_USUARIO}. Por onde começamos?</h1>
                <p>Pergunte sobre a fila, um cliente ou a carteira em atraso.</p>
            </div>
        """, unsafe_allow_html=True)

        c1, c2, c3 = st.columns(3)
        c1.markdown(f'<div class="stat"><small>Valor em atraso</small><b>{valor_em_atraso}</b></div>', unsafe_allow_html=True)
        c2.markdown(f'<div class="stat"><small>Clientes na fila</small><b>{int(resumo["clientes"])}</b></div>', unsafe_allow_html=True)
        c3.markdown(f'<div class="stat"><small>Para ligar hoje</small><b>{int(resumo["ligar"])}</b></div>', unsafe_allow_html=True)

        st.write("")
        with st.container(key="sugestoes"):
            colunas = st.columns(2)
            for i, (icone, titulo, descricao, _, pergunta) in enumerate(SUGESTOES):
                with colunas[i % 2]:
                    if st.button(f"{icone} **{titulo}**  \n{descricao}", key=f"sug_{i}", width="stretch"):
                        perguntar(pergunta, PERGUNTAS[pergunta])
                        st.rerun()

    # ---------- conversa ----------
    else:
        pendentes = []
        for item in st.session_state.historico:
            tabela = item["tabela"]
            with st.chat_message("user", avatar="🧑‍💼"):
                st.write(item["pergunta"])
            with st.chat_message("assistant", avatar=":material/auto_awesome:"):
                st.markdown(f'<div class="passo">✓ Consultou a camada gold · {len(tabela)} linhas · '
                            f'{item["duracao"]:.1f} s</div>', unsafe_allow_html=True)
                if tabela.empty:
                    st.write("Nenhum cliente encontrado para essa pergunta.")
                elif item["texto"] is None:
                    pendentes.append((item, st.empty()))
                else:
                    st.markdown(item["texto"])
                if not tabela.empty:
                    with st.expander("Ver dados"):
                        st.dataframe(tabela, hide_index=True, column_config=ROTULOS, width="stretch")

        with st.container(key="chips"):
            atalhos = st.columns(len(SUGESTOES))
            for i, (icone, _, _, curto, pergunta) in enumerate(SUGESTOES):
                if atalhos[i].button(f"{icone} {curto}", key=f"chip_{i}", width="stretch"):
                    perguntar(pergunta, PERGUNTAS[pergunta])
                    st.rerun()

    pergunta_livre = st.chat_input("Pergunte sobre a fila de cobrança...")
    if pergunta_livre:
        perguntar(pergunta_livre)
        st.rerun()

    st.markdown('<div class="aviso">O agente responde com base na camada gold. Confira os dados antes de agir.</div>', unsafe_allow_html=True)

    if st.session_state.historico:
        for item, espaco in pendentes:
            with espaco.container():
                escrever_resposta(item)


@st.cache_data(ttl=3600, show_spinner=False)
def grafico_em_cache(dimensao, medida):
    return buscar_grafico(dimensao, medida)


def pagina_graficos():
    st.markdown("## 📊 Gerador de gráficos")
    st.caption("Escolha como agrupar e o que medir. Fonte: gold_fila_cobranca + gold_cliente_360")

    col1, col2 = st.columns(2)
    dimensao = col1.selectbox("Agrupar por", list(DIMENSOES))
    medida = col2.selectbox("Medir", list(MEDIDAS))

    tabela = grafico_em_cache(dimensao, medida)

    with st.container(border=True):
        st.markdown(f"**{medida} por {dimensao.lower()}**")
        if tabela.empty:
            st.info("Nenhum dado para essa combinação.")
        else:
            st.altair_chart(grafico_barras(tabela, medida), width="stretch")

    if not tabela.empty and st.button("🤖 Explicar gráfico"):
        with st.chat_message("assistant", avatar=":material/auto_awesome:"):
            escrever_resposta({"pergunta": f"Explique o gráfico de {medida} por {dimensao}.",
                               "tabela": tabela, "texto": None})

    with st.expander("Ver dados"):
        st.dataframe(tabela, hide_index=True, width="stretch",
                     column_config={"categoria": dimensao, "valor": medida})


if pagina == "💬 Agente":
    pagina_agente()
else:
    pagina_graficos()