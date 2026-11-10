import altair as alt
import pandas as pd


def formatar_valor(valor, medida):
    if "R$" in medida:
        if valor >= 1_000_000:
            return f"R$ {valor / 1_000_000:.2f} mi".replace(".", ",")
        if valor >= 1_000:
            return f"R$ {valor / 1_000:.0f} mil"
        return f"R$ {valor:.0f}"
    if "médios" in medida:
        return f"{valor:.1f}".replace(".", ",")
    return f"{valor:.0f}"


def grafico_barras(tabela, medida):
    dados = tabela.copy()
    dados["categoria"] = dados["categoria"].astype(str)
    dados["valor"] = pd.to_numeric(dados["valor"])
    dados["rotulo"] = [formatar_valor(v, medida) for v in dados["valor"]]

    base = alt.Chart(dados).encode(
        y=alt.Y("categoria:N", sort="-x", title=None),
        x=alt.X("valor:Q", title=None, axis=None),
    )
    barras = base.mark_bar(color="#6B7280", cornerRadiusEnd=4, height=22)
    rotulos = base.mark_text(align="left", dx=6, fontSize=13, color="#9CA3AF").encode(text="rotulo:N")

    return (barras + rotulos).properties(height=max(len(dados) * 38, 120))