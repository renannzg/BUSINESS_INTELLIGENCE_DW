import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# ==================================================
# CONFIGURAÇÃO
# ==================================================

st.set_page_config(
    page_title="Dashboard COVID - Data Warehouse",
    layout="wide"
)

# ==================================================
# CONEXÃO COM DW
# ==================================================

@st.cache_resource
def conectar():
    return create_engine(
        "postgresql+psycopg2://postgres:renan1234@localhost:5432/dw_covid"
    )

engine = conectar()

# ==================================================
# TÍTULO
# ==================================================

st.title("📊 Dashboard COVID-19 - Data Warehouse")
st.markdown("""
Dashboard conectado diretamente ao Data Warehouse PostgreSQL.
Os dados não são mais lidos do CSV, mas sim das tabelas fato e dimensões do DW.
""")

# ==================================================
# MÉTRICAS GERAIS
# ==================================================

query_metricas = """
SELECT
    COUNT(*) AS total_notificacoes,
    SUM(flag_confirmado) AS total_confirmados,
    SUM(flag_obito_covid) AS total_obitos,
    SUM(flag_cura) AS total_curas
FROM dw.fato_notificacao_covid
"""

metricas = pd.read_sql(query_metricas, engine)

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "Notificações",
    f"{int(metricas['total_notificacoes'][0]):,}"
)

col2.metric(
    "Confirmados",
    f"{int(metricas['total_confirmados'][0]):,}"
)

col3.metric(
    "Óbitos",
    f"{int(metricas['total_obitos'][0]):,}"
)

col4.metric(
    "Curas",
    f"{int(metricas['total_curas'][0]):,}"
)

st.divider()

# ==================================================
# CLASSIFICAÇÃO
# ==================================================

st.header("Distribuição por Classificação")

query_classificacao = """
SELECT
    c.classificacao,
    COUNT(*) AS total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_classificacao c
    ON f.sk_class = c.sk_class
GROUP BY c.classificacao
ORDER BY total DESC
"""

df_class = pd.read_sql(query_classificacao, engine)

fig, ax = plt.subplots(figsize=(8,4))
ax.barh(df_class["classificacao"], df_class["total"])
ax.set_xlabel("Quantidade")
st.pyplot(fig)

# ==================================================
# SEXO
# ==================================================

st.header("Distribuição por Sexo")

query_sexo = """
SELECT
    p.sexo,
    COUNT(*) AS total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_perfil_paciente p
    ON f.sk_perfil = p.sk_perfil
GROUP BY p.sexo
ORDER BY total DESC
"""

df_sexo = pd.read_sql(query_sexo, engine)

fig, ax = plt.subplots(figsize=(6,6))
ax.pie(
    df_sexo["total"],
    labels=df_sexo["sexo"],
    autopct="%1.1f%%"
)
st.pyplot(fig)

# ==================================================
# EVOLUÇÃO TEMPORAL
# ==================================================

st.header("Evolução Temporal")

query_tempo = """
SELECT
    t.ano,
    COUNT(*) AS total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_tempo t
    ON f.sk_data_notificacao = t.sk_tempo
GROUP BY t.ano
ORDER BY t.ano
"""

df_tempo = pd.read_sql(query_tempo, engine)

fig, ax = plt.subplots(figsize=(8,4))
ax.plot(df_tempo["ano"], df_tempo["total"])
ax.set_xlabel("Ano")
ax.set_ylabel("Notificações")
st.pyplot(fig)

# ==================================================
# LETALIDADE
# ==================================================

st.header("Indicadores de Letalidade")

query_letalidade = """
SELECT
    SUM(flag_confirmado) AS confirmados,
    SUM(flag_obito_covid) AS obitos
FROM dw.fato_notificacao_covid
"""

df_letalidade = pd.read_sql(query_letalidade, engine)

confirmados = int(df_letalidade["confirmados"][0])
obitos = int(df_letalidade["obitos"][0])

if confirmados > 0:
    taxa = (obitos / confirmados) * 100
else:
    taxa = 0

st.metric(
    "Taxa de Letalidade (%)",
    f"{taxa:.2f}%"
)

# ==================================================
# TOP MUNICÍPIOS
# ==================================================

st.header("Top 10 Municípios")

query_municipios = """
SELECT
    l.municipio,
    COUNT(*) AS total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l
    ON f.sk_local = l.sk_local
GROUP BY l.municipio
ORDER BY total DESC
LIMIT 10
"""

try:
    df_municipios = pd.read_sql(query_municipios, engine)

    fig, ax = plt.subplots(figsize=(10,4))
    ax.bar(df_municipios["municipio"], df_municipios["total"])
    plt.xticks(rotation=45)
    st.pyplot(fig)

except Exception:
    st.warning(
        "Dimensão de localidade não disponível ou não populada."
    )

# ==================================================
# TABELA ANALÍTICA
# ==================================================

st.header("Resumo Analítico")

st.dataframe(
    df_class,
    use_container_width=True
)

st.success("Dashboard alimentado diretamente pelo Data Warehouse PostgreSQL.")