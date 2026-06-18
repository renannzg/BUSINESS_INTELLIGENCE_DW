import pandas as pd
import time

inicio = time.time()

df = pd.read_csv(
    "MICRODADOS.csv",
    sep=";",
    encoding="latin-1",
    on_bad_lines="skip"
)

fim = time.time()

print(f"Tempo CSV: {fim - inicio:.2f} segundos")


