````markdown
# Projeto C3 - Business Intelligence

## Integração de Data Warehouse, ETL e Dashboard Analítico para Dados de COVID-19

## 📖 Sobre o Projeto

Este projeto foi desenvolvido como atividade prática da disciplina de **Business Intelligence**, consolidando os conhecimentos adquiridos nas etapas anteriores:

- **C1:** Desenvolvimento da camada de visualização utilizando Streamlit.
- **C2:** Construção do Data Warehouse e modelagem dimensional.
- **C3:** Integração do ETL, Data Warehouse e Dashboard Analítico.

O objetivo principal foi migrar uma solução baseada em leitura direta de arquivos CSV para uma arquitetura analítica utilizando um **Data Warehouse PostgreSQL**, permitindo melhor desempenho, organização e escalabilidade.

---

# 🏗 Arquitetura da Solução

```text
MICRODADOS.csv
      │
      ▼
   ETL (Python)
      │
      ▼
 PostgreSQL
(Data Warehouse)
      │
      ▼
  Streamlit
(Dashboard BI)
```

---

# 🛠 Tecnologias Utilizadas

- Python
- Pandas
- PostgreSQL
- SQLAlchemy
- Psycopg2
- Streamlit
- Matplotlib
- SQL

---

# 📊 Modelo Dimensional

Foi utilizado um modelo dimensional do tipo **Esquema Estrela (Star Schema)**.

## Tabela Fato

### fato_notificacao_covid

Armazena os eventos de notificação e indicadores analíticos:

- Quantidade de notificações
- Casos confirmados
- Óbitos
- Internações
- Casos de cura
- Idade do paciente
- Intervalos entre datas

## Tabelas Dimensão

- dim_tempo
- dim_localidade
- dim_perfil_paciente
- dim_classificacao
- dim_sintomas
- dim_comorbidade
- dim_teste

Todas as dimensões utilizam **Surrogate Keys** para melhor desempenho e integridade do modelo.

---

# 🔄 Processo ETL

## Extract

Os dados são extraídos do arquivo:

```text
MICRODADOS.csv
```

## Transform

Foram aplicados:

- Tratamento de valores nulos
- Padronização de textos
- Conversão de datas
- Limpeza de registros
- Criação de indicadores analíticos
- Criação de chaves substitutas

## Load

Os dados são carregados nas camadas:

### Staging

```text
stg.notificacao_raw
```

### Data Warehouse

```text
dw.*
```

### Data Mart

```text
mart.*
```

---

# 🗄 Estrutura do Projeto

```text
Projeto_C3_COVID/
│
├── data/
│   └── MICRODADOS.csv
│
├── sql/
│   └── dw_covid.sql
│
├── etl/
│   └── etl_covid.py
│
├── dashboard/
│   └── app_dw.py
│
├── benchmark/
│   ├── teste_csv.py
│   └── teste_dw.py
│
├── docs/
│   └── relatorio_c3.pdf
│
├── requirements.txt
│
└── README.md
```

---

# 📈 Dashboard

O dashboard foi desenvolvido utilizando Streamlit e consome os dados diretamente do Data Warehouse PostgreSQL.

## Funcionalidades

### Indicadores Gerais

- Total de notificações
- Total de confirmados
- Total de óbitos
- Total de curas

### Distribuição por Classificação

Análise dos casos por classificação.

### Distribuição por Sexo

Distribuição percentual dos pacientes.

### Evolução Temporal

Evolução dos registros ao longo do tempo.

### Top Municípios

Municípios com maior número de notificações.

### Taxa de Letalidade

Indicador de letalidade dos casos confirmados.

---

# ⚡ Comparação de Desempenho

Foi realizada uma comparação entre a versão original baseada em CSV e a nova versão integrada ao Data Warehouse.

| Método | Tempo |
|----------|----------|
| CSV | 21,22 s |
| Data Warehouse PostgreSQL | 0,56 s |

## Resultado

A solução baseada em Data Warehouse apresentou desempenho aproximadamente:

### 🚀 38x mais rápido

em comparação à leitura direta do arquivo CSV.

---

# 📌 Principais Benefícios Obtidos

- Melhor desempenho nas consultas
- Menor consumo de memória
- Maior escalabilidade
- Estrutura analítica adequada para BI
- Separação entre armazenamento e visualização
- Facilidade para futuras expansões

---

# ▶ Como Executar

## 1. Instalar Dependências

```bash
pip install -r requirements.txt
```

## 2. Configurar PostgreSQL

Criar o banco:

```sql
CREATE DATABASE dw_covid;
```

Executar o script:

```text
sql/dw_covid.sql
```

---

## 3. Executar Dashboard

```bash
streamlit run app_dw.py
```

---

# 👨‍💻 Autor

Projeto desenvolvido para a disciplina de Business Intelligence.

Aluno: **Renan Miguel**

Instituição: **FAESA**

Ano: **2026**
````
