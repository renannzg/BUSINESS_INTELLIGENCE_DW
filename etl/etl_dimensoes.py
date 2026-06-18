"""ETL: popula as dimensoes a partir de stg.notificacao_raw."""
from sqlalchemy import create_engine, text

ENGINE = create_engine(
    "postgresql+psycopg2://postgres:postgres@localhost:5432/dw_covid"
)

def carregar_dimensao(nome_tabela, colunas_origem, colunas_destino):
    """
    Extrai combinacoes distintas da staging e insere na dimensao.
    Usa ON CONFLICT DO NOTHING para idempotencia.
    """
    col_src = ", ".join(colunas_origem)
    col_dst = ", ".join(colunas_destino)
    sql = f"""
    INSERT INTO dw.{nome_tabela} ({col_dst})
    SELECT DISTINCT {col_src}
    FROM stg.notificacao_raw
    ON CONFLICT ({col_dst}) DO NOTHING;
    """
    with ENGINE.begin() as conn:
        conn.execute(text(sql))
    print(f"[OK] Dimensao {nome_tabela} carregada.")

# --- DIM_LOCALIDADE ---
carregar_dimensao(
    "dim_localidade",
    ["municipio", "bairro"],
    ["municipio", "bairro"]
)

# --- DIM_CLASSIFICACAO ---
carregar_dimensao(
    "dim_classificacao",
    ["classificacao", "evolucao", "criterio_confirmacao", "status_notificacao"],
    ["classificacao", "evolucao", "criterio_confirmacao", "status_notificacao"]
)

# --- DIM_PERFIL_PACIENTE ---
carregar_dimensao(
    "dim_perfil_paciente",
    ["sexo", "faixa_etaria", "raca_cor", "escolaridade", "gestante", "profissional_saude", "morador_rua", "possui_deficiencia"],
    ["sexo", "faixa_etaria", "raca_cor", "escolaridade", "gestante", "profissional_saude", "morador_rua", "possui_deficiencia"]
)

# --- DIM_SINTOMAS (junk) ---
carregar_dimensao(
    "dim_sintomas",
    ["febre", "dif_respiratoria", "tosse", "coriza", "dor_garganta", "diarreia", "cefaleia"],
    ["febre", "dif_respiratoria", "tosse", "coriza", "dor_garganta", "diarreia", "cefaleia"]
)

# --- DIM_COMORBIDADE (junk) ---
carregar_dimensao(
    "dim_comorbidade",
    ["com_pulmao", "com_cardio", "com_renal", "com_diabetes", "com_tabagismo", "com_obesidade"],
    ["com_pulmao", "com_cardio", "com_renal", "com_diabetes", "com_tabagismo", "com_obesidade"]
)

# --- DIM_TESTE ---
carregar_dimensao(
    "dim_teste",
    ["tipo_teste_rapido", "resultado_rt_pcr", "resultado_teste_rap", "resultado_sorologia", "resultado_sorol_igg"],
    ["tipo_teste_rapido", "resultado_rt_pcr", "resultado_teste_rap", "resultado_sorologia", "resultado_sorol_igg"]
)
