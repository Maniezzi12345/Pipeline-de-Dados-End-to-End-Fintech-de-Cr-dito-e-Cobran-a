import streamlit as st
from banco import consultar, buscar_resumo, buscar_contexto
from agente_ia import responder
from perguntas import PERGUNTAS

DATA_BASE = "22/10/2026"

st.set_page_config(page_title="Agente de Cobrança", page_icon="💼", layout="wide")

st.markdown("""
<style>
    footer {visibility: hidden;}
    .block-container {padding-top: 2rem; max-width: 1100px;}
    [data-testid="stMetricValue"] {font-size: 1.6rem;}
    [data-testid="stMetricLabel"] p {opacity: 0.7;}
    [data-testid="stSidebar"] .stButton button {text-align: left; justify-content: flex-start;}
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


@st.cache_data(ttl=3600)
def resumo_em_cache():
    return buscar_resumo()


@st.cache_data(ttl=3600)
def responder_com_cache(pergunta, tabela):
    return responder(pergunta, tabela)


def perguntar(pergunta, tabela):
    if tabela.empty:
        texto = "Nenhum cliente encontrado para essa pergunta."
    else:
        with st.spinner("O agente está analisando os dados..."):
            texto = responder_com_cache(pergunta, tabela)
    st.session_state.historico.append((pergunta, texto, tabela))


if "historico" not in st.session_state:
    st.session_state.historico = []

# ---------- menu lateral ----------

with st.sidebar:
    st.markdown("### 💼 Agente de Cobrança")
    st.caption("Fintech de crédito · camada gold")
    st.divider()
    st.markdown("**Perguntas prontas**")
    for pergunta, sql in PERGUNTAS.items():
        if st.button(pergunta, width="stretch"):
            perguntar(pergunta, consultar(sql))
    st.divider()
    if st.button("🗑️ Limpar conversa", width="stretch"):
        st.session_state.historico = []
    st.caption(f"Dados atualizados até {DATA_BASE}")

# ---------- cabeçalho ----------
st.markdown("## Central de cobrança")
st.caption(f"Data-base: {DATA_BASE} · Fonte: analytics_gold.gold_fila_cobranca")

resumo = resumo_em_cache()
col1, col2, col3, col4 = st.columns(4)
with col1:
    with st.container(border=True):
        st.metric("Valor em atraso", formatar_reais(float(resumo["valor_em_atraso"])))
col1, col2, col3, col4 = st.columns(4)
with col1:
    with st.container(border=True):
        st.metric("Valor em atraso", formatar_reais(float(resumo["valor_em_atraso"])))
with col2:
    with st.container(border=True):
        st.metric("Clientes na fila", int(resumo["clientes"]))
with col3:
    with st.container(border=True):
        st.metric("Para ligar", int(resumo["ligar"]))
with col4:
    with st.container(border=True):
        st.metric("Aguardando promessa", int(resumo["aguardando"]))