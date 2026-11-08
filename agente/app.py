import streamlit as st
from banco import buscar_fila

st.set_page_config(page_title="Agente de Cobrança", layout="wide")

st.title("📋 Fila de cobrança do dia")

limite = st.slider("Quantos clientes mostrar?", min_value=5, max_value=50, value=10)

fila = buscar_fila(limite)

st.dataframe(fila, hide_index=True)