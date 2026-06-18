import pandas as pd
import time
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://postgres:renan1234@localhost:5432/dw_covid"
)

inicio = time.time()

df = pd.read_sql("""
SELECT
    c.classificacao,
    COUNT(*) as total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_classificacao c
ON f.sk_class = c.sk_class
GROUP BY c.classificacao
""", engine)

fim = time.time()

print(f"Tempo DW: {fim - inicio:.2f} segundos")