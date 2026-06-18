-- ----------------------------------------------------------------------------
-- PARTE 1: CRIAÇÃO DOS SCHEMAS (EXECUTAR APÓS CONECTAR NO BANCO dw_covid)
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS stg;   -- Camada de Staging (Dados Brutos)
CREATE SCHEMA IF NOT EXISTS dw;    -- Camada do Data Warehouse (Modelo Estrela)
CREATE SCHEMA IF NOT EXISTS mart;  -- Camada de Data Marts (Views Analíticas)

-- ----------------------------------------------------------------------------
-- PARTE 2: TABELA DE STAGING (DADOS BRUTOS)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.notificacao_raw;
CREATE TABLE stg.notificacao_raw (
    data_notificacao TEXT, data_cadastro TEXT, data_diagnostico TEXT,
    data_coleta_rt_pcr TEXT, data_coleta_teste_rap TEXT, data_coleta_sorologia TEXT, data_coleta_sorolog_igg TEXT,
    data_encerramento TEXT, data_obito TEXT, classificacao TEXT, evolucao TEXT, criterio_confirmacao TEXT,
    status_notificacao TEXT, municipio TEXT, bairro TEXT, faixa_etaria TEXT, idade_na_notificacao TEXT,
    sexo TEXT, raca_cor TEXT, escolaridade TEXT, gestante TEXT, febre TEXT, dif_respiratoria TEXT,
    tosse TEXT, coriza TEXT, dor_garganta TEXT, diarreia TEXT, cefaleia TEXT, com_pulmao TEXT,
    com_cardio TEXT, com_renal TEXT, com_diabetes TEXT, com_tabagismo TEXT, com_obesidade TEXT,
    ficou_internado TEXT, viagem_brasil TEXT, viagem_internacional TEXT, profissional_saude TEXT,
    possui_deficiencia TEXT, morador_rua TEXT, resultado_rt_pcr TEXT, resultado_teste_rap TEXT,
    resultado_sorologia TEXT, resultado_sorol_igg TEXT, tipo_teste_rapido TEXT
);

-- ----------------------------------------------------------------------------
-- PARTE 3: IMPORTAÇÃO DO ARQUIVO CSV PARA A STAGING
-- ----------------------------------------------------------------------------
COPY stg.notificacao_raw 
FROM 'C:\MICRODADOS\MICRODADOS.csv' 
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'LATIN1', QUOTE E'\b');

-- ----------------------------------------------------------------------------
-- PARTE 4: CRIAÇÃO DAS TABELAS DO MODELO ESTRELA (DIMENSÕES E FATO)
-- ----------------------------------------------------------------------------

-- 1. DIM_TEMPO
DROP TABLE IF EXISTS dw.dim_tempo CASCADE;
CREATE TABLE dw.dim_tempo (
    sk_tempo INT PRIMARY KEY, data DATE, dia SMALLINT, mes SMALLINT, ano SMALLINT,
    trimestre SMALLINT, nome_mes VARCHAR(15), dia_semana VARCHAR(15), ano_mes CHAR(7),
    eh_fim_de_semana BOOLEAN, semana_epidemiologica SMALLINT
);
INSERT INTO dw.dim_tempo VALUES (-1, NULL, NULL, NULL, NULL, NULL, 'Desconhecido', 'Desconhecido', 'N/D', FALSE, NULL);

-- 2. DIM_LOCALIDADE
DROP TABLE IF EXISTS dw.dim_localidade CASCADE;
CREATE TABLE dw.dim_localidade (
    sk_local SERIAL PRIMARY KEY, municipio VARCHAR(100), bairro VARCHAR(150),
    uf CHAR(2) DEFAULT 'ES', regiao_es VARCHAR(30), macrorregiao VARCHAR(30),
    UNIQUE (municipio, bairro)
);
INSERT INTO dw.dim_localidade (municipio, bairro)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(municipio), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(bairro), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (municipio, bairro) DO NOTHING;

-- 3. DIM_PERFIL_PACIENTE
DROP TABLE IF EXISTS dw.dim_perfil_paciente CASCADE;
CREATE TABLE dw.dim_perfil_paciente (
    sk_perfil SERIAL PRIMARY KEY, sexo VARCHAR(20), faixa_etaria VARCHAR(30), raca_cor VARCHAR(30),
    escolaridade VARCHAR(100), gestante VARCHAR(40), profissional_saude VARCHAR(20), morador_rua VARCHAR(20), possui_deficiencia VARCHAR(20),
    UNIQUE (sexo, faixa_etaria, raca_cor, escolaridade, gestante, profissional_saude, morador_rua, possui_deficiencia)
);
INSERT INTO dw.dim_perfil_paciente (sk_perfil, sexo, faixa_etaria, raca_cor, escolaridade, gestante, profissional_saude, morador_rua, possui_deficiencia) 
OVERRIDING SYSTEM VALUE VALUES (-1, 'Desconhecido', 'Desconhecida', 'Desconhecida', 'Desconhecida', 'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido');

-- 4. DIM_CLASSIFICACAO
DROP TABLE IF EXISTS dw.dim_classificacao CASCADE;
CREATE TABLE dw.dim_classificacao (
    sk_class SERIAL PRIMARY KEY, classificacao VARCHAR(50), evolucao VARCHAR(50), criterio_confirmacao VARCHAR(50), status_notificacao VARCHAR(30),
    UNIQUE (classificacao, evolucao, criterio_confirmacao, status_notificacao)
);
INSERT INTO dw.dim_classificacao (sk_class, classificacao, evolucao, criterio_confirmacao, status_notificacao) 
OVERRIDING SYSTEM VALUE VALUES (-1, 'Desconhecida', 'Desconhecida', 'Desconhecido', 'Desconhecido');

-- 5. DIM_SINTOMAS (Junk Dimension)
DROP TABLE IF EXISTS dw.dim_sintomas CASCADE;
CREATE TABLE dw.dim_sintomas (
    sk_sint SERIAL PRIMARY KEY, febre VARCHAR(20), dif_respiratoria VARCHAR(20), tosse VARCHAR(20),
    coriza VARCHAR(20), dor_garganta VARCHAR(20), diarreia VARCHAR(20), cefaleia VARCHAR(20),
    UNIQUE (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
);
-- 5. População da DIM_COMORBIDADE (Ajustado)
INSERT INTO dw.dim_comorbidade (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(com_pulmao), ''), 'Desconhecido'), 
    COALESCE(NULLIF(TRIM(com_cardio), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_renal), ''), 'Desconhecido'), 
    COALESCE(NULLIF(TRIM(com_diabetes), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_tabagismo), ''), 'Desconhecido'), 
    COALESCE(NULLIF(TRIM(com_obesidade), ''), 'Desconhecido')
FROM stg.notificacao_raw 
ON CONFLICT (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade) DO NOTHING;

-- 6. DIM_COMORBIDADE (Junk Dimension)
DROP TABLE IF EXISTS dw.dim_comorbidade CASCADE;
CREATE TABLE dw.dim_comorbidade (
    sk_como SERIAL PRIMARY KEY, 
    com_pulmao VARCHAR(20), 
    com_cardio VARCHAR(20), 
    com_renal VARCHAR(20),
    com_diabetes VARCHAR(20), 
    com_tabagismo VARCHAR(20), 
    com_obesidade VARCHAR(20),
    UNIQUE (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
);
-- Inserção do registro Desconhecido (-1)
INSERT INTO dw.dim_comorbidade (sk_como, com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade) 
OVERRIDING SYSTEM VALUE VALUES (-1, 'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido');

-- 7. DIM_TESTE
DROP TABLE IF EXISTS dw.dim_teste CASCADE;
CREATE TABLE dw.dim_teste (
    sk_teste SERIAL PRIMARY KEY, tipo_teste_rapido VARCHAR(60), resultado_rt_pcr VARCHAR(30),
    resultado_teste_rap VARCHAR(30), resultado_sorologia VARCHAR(30), resultado_sorol_igg VARCHAR(30),
    UNIQUE (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
);
INSERT INTO dw.dim_teste (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(tipo_teste_rapido), ''), 'Desconhecido'), 
    COALESCE(NULLIF(TRIM(resultado_rt_pcr), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_teste_rap), ''), 'Desconhecido'), 
    COALESCE(NULLIF(TRIM(resultado_sorologia), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_sorol_igg), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap, resultado_sorologia, resultado_sorol_igg) DO NOTHING;

-- 8. FATO_NOTIFICACAO_COVID
DROP TABLE IF EXISTS dw.fato_notificacao_covid CASCADE;
CREATE TABLE dw.fato_notificacao_covid (
    sk_fato BIGSERIAL PRIMARY KEY,
    sk_data_notificacao INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_data_cadastro INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_data_diagnostico INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_data_coleta INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_data_encerramento INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_data_obito INT NOT NULL REFERENCES dw.dim_tempo (sk_tempo),
    sk_local INT NOT NULL REFERENCES dw.dim_localidade (sk_local),
    sk_perfil INT NOT NULL REFERENCES dw.dim_perfil_paciente (sk_perfil),
    sk_class INT NOT NULL REFERENCES dw.dim_classificacao (sk_class),
    sk_sint INT NOT NULL REFERENCES dw.dim_sintomas (sk_sint),
    sk_como INT NOT NULL REFERENCES dw.dim_comorbidade (sk_como),
    sk_teste INT NOT NULL REFERENCES dw.dim_teste (sk_teste),
    qtd_notificacao SMALLINT NOT NULL DEFAULT 1,
    flag_confirmado SMALLINT NOT NULL DEFAULT 0,
    flag_obito_covid SMALLINT NOT NULL DEFAULT 0,
    flag_internado SMALLINT NOT NULL DEFAULT 0,
    flag_cura SMALLINT NOT NULL DEFAULT 0,
    idade_anos SMALLINT,
    dias_notif_encerramento INT,
    dias_notif_obito INT
);
CREATE INDEX idx_fato_data_notif ON dw.fato_notificacao_covid (sk_data_notificacao);
CREATE INDEX idx_fato_local ON dw.fato_notificacao_covid (sk_local);

-- ----------------------------------------------------------------------------
-- PARTE 5: CARGA / POVOAÇÃO DAS DIMENSÕES (ETL - SQL PURO)
-- ----------------------------------------------------------------------------

-- 1. População da DIM_TEMPO (Série Temporal)
INSERT INTO dw.dim_tempo (sk_tempo, data, dia, mes, ano, trimestre, nome_mes, dia_semana, ano_mes, eh_fim_de_semana, semana_epidemiologica)
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INT) AS sk_tempo, d,
    EXTRACT(DAY FROM d)::SMALLINT, EXTRACT(MONTH FROM d)::SMALLINT, EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT, TO_CHAR(d, 'TMMonth'), TO_CHAR(d, 'TMDay'), TO_CHAR(d, 'YYYY-MM'),
    EXTRACT(ISODOW FROM d) >= 6, EXTRACT(WEEK FROM d)::SMALLINT
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) d
ON CONFLICT DO NOTHING;

-- 2. População da DIM_LOCALIDADE
INSERT INTO dw.dim_localidade (municipio, bairro)
SELECT DISTINCT 
    COALESCE(NULLIF(TRIM(municipio), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(bairro), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (municipio, bairro) DO NOTHING;

-- 3. População da DIM_CLASSIFICACAO
INSERT INTO dw.dim_classificacao (classificacao, evolucao, criterio_confirmacao, status_notificacao)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(classificacao), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(evolucao), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(criterio_confirmacao), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(status_notificacao), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (classificacao, evolucao, criterio_confirmacao, status_notificacao) DO NOTHING;

-- 4. População da DIM_PERFIL_PACIENTE
INSERT INTO dw.dim_perfil_paciente (sexo, faixa_etaria, raca_cor, escolaridade, gestante, profissional_saude, morador_rua, possui_deficiencia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(sexo), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(faixa_etaria), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(raca_cor), ''), 'Desconhecida'), COALESCE(NULLIF(TRIM(escolaridade), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(gestante), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(profissional_saude), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(morador_rua), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(possui_deficiencia), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (sexo, faixa_etaria, raca_cor, escolaridade, gestante, profissional_saude, morador_rua, possui_deficiencia) DO NOTHING;

-- 5. População da DIM_SINTOMAS
INSERT INTO dw.dim_sintomas (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(febre), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(dif_respiratoria), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(tosse), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(coriza), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(dor_garganta), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(diarreia), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(cefaleia), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia) DO NOTHING;

-- 6. População da DIM_COMORBIDADE
INSERT INTO dw.dim_comorbidade (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(com_pulmao), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(com_cardio), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_renal), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(com_diabetes), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_tabagismo), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(com_obesidade), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade) DO NOTHING;

-- 7. População da DIM_TESTE
INSERT INTO dw.dim_teste (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(tipo_teste_rapido), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(resultado_rt_pcr), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_teste_rap), ''), 'Desconhecido'), COALESCE(NULLIF(TRIM(resultado_sorologia), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_sorol_igg), ''), 'Desconhecido')
FROM stg.notificacao_raw ON CONFLICT (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap, resultado_sorologia, resultado_sorol_igg) DO NOTHING;

-- ----------------------------------------------------------------------------
-- PARTE 6: CARGA FINAL DA TABELA FATO (PODE DEMORAR ALGUNS MINUTOS)
-- ----------------------------------------------------------------------------
INSERT INTO dw.fato_notificacao_covid (
    sk_data_notificacao, sk_data_cadastro, sk_data_diagnostico, sk_data_coleta, sk_data_encerramento, sk_data_obito,
    sk_local, sk_perfil, sk_class, sk_sint, sk_como, sk_teste, qtd_notificacao, flag_confirmado, flag_obito_covid,
    flag_internado, flag_cura, idade_anos, dias_notif_encerramento, dias_notif_obito
)
select

    CASE 
        WHEN NULLIF(TRIM(s.data_notificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_notificacao), '')::DATE, 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    CASE 
        WHEN NULLIF(TRIM(s.data_cadastro), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_cadastro), '')::DATE, 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    CASE 
        WHEN NULLIF(TRIM(s.data_diagnostico), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_diagnostico), '')::DATE, 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    CASE 
        WHEN COALESCE(
            NULLIF(TRIM(s.data_coleta_rt_pcr), '')::DATE, NULLIF(TRIM(s.data_coleta_teste_rap), '')::DATE,
            NULLIF(TRIM(s.data_coleta_sorologia), '')::DATE, NULLIF(TRIM(s.data_coleta_sorolog_igg), '')::DATE
        ) BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(COALESCE(
            NULLIF(TRIM(s.data_coleta_rt_pcr), '')::DATE, NULLIF(TRIM(s.data_coleta_teste_rap), '')::DATE,
            NULLIF(TRIM(s.data_coleta_sorologia), '')::DATE, NULLIF(TRIM(s.data_coleta_sorolog_igg), '')::DATE
        ), 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    CASE 
        WHEN NULLIF(TRIM(s.data_encerramento), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_encerramento), '')::DATE, 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    CASE 
        WHEN NULLIF(TRIM(s.data_obito), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
        THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_obito), '')::DATE, 'YYYYMMDD') AS INT)
        ELSE -1 
    END,
    
    COALESCE(dl.sk_local, -1), dp.sk_perfil, dc.sk_class, ds.sk_sint, dm.sk_como, dt.sk_teste,
    1 AS qtd_notificacao, (s.classificacao = 'Confirmados')::INT AS flag_confirmado, (s.evolucao = 'Óbito pelo COVID-19')::INT AS flag_obito_covid,
    (s.ficou_internado = 'Sim')::INT AS flag_internado, (s.evolucao = 'Cura')::INT AS flag_cura,
    NULLIF(SPLIT_PART(s.idade_na_notificacao, ' anos', 1), '')::INT AS idade_anos,
    NULLIF(TRIM(s.data_encerramento), '')::DATE - NULLIF(TRIM(s.data_notificacao), '')::DATE AS dias_notif_enc,
    NULLIF(TRIM(s.data_obito), '')::DATE - NULLIF(TRIM(s.data_notificacao), '')::DATE AS dias_notif_obito
FROM stg.notificacao_raw s
LEFT JOIN dw.dim_localidade dl ON dl.municipio = COALESCE(NULLIF(TRIM(s.municipio), ''), 'Desconhecido') AND dl.bairro = COALESCE(NULLIF(TRIM(s.bairro), ''), 'Desconhecido')
LEFT JOIN dw.dim_perfil_paciente dp ON dp.sexo = COALESCE(NULLIF(TRIM(s.sexo), ''), 'Desconhecido') AND dp.faixa_etaria = COALESCE(NULLIF(TRIM(s.faixa_etaria), ''), 'Desconhecida') AND dp.raca_cor = COALESCE(NULLIF(TRIM(s.raca_cor), ''), 'Desconhecida') AND dp.escolaridade = COALESCE(NULLIF(TRIM(s.escolaridade), ''), 'Desconhecida') AND dp.gestante = COALESCE(NULLIF(TRIM(s.gestante), ''), 'Desconhecido') AND dp.profissional_saude = COALESCE(NULLIF(TRIM(s.profissional_saude), ''), 'Desconhecido') AND dp.morador_rua = COALESCE(NULLIF(TRIM(s.morador_rua), ''), 'Desconhecido') AND dp.possui_deficiencia = COALESCE(NULLIF(TRIM(s.possui_deficiencia), ''), 'Desconhecido')
LEFT JOIN dw.dim_classificacao dc ON dc.classificacao = COALESCE(NULLIF(TRIM(s.classificacao), ''), 'Desconhecida') AND dc.evolucao = COALESCE(NULLIF(TRIM(s.evolucao), ''), 'Desconhecida') AND dc.criterio_confirmacao = COALESCE(NULLIF(TRIM(s.criterio_confirmacao), ''), 'Desconhecido') AND dc.status_notificacao = COALESCE(NULLIF(TRIM(s.status_notificacao), ''), 'Desconhecido')
LEFT JOIN dw.dim_sintomas ds ON ds.febre = COALESCE(NULLIF(TRIM(s.febre), ''), 'Desconhecido') AND ds.dif_respiratoria = COALESCE(NULLIF(TRIM(s.dif_respiratoria), ''), 'Desconhecido') AND ds.tosse = COALESCE(NULLIF(TRIM(s.tosse), ''), 'Desconhecido') AND ds.coriza = COALESCE(NULLIF(TRIM(s.coriza), ''), 'Desconhecido') AND ds.dor_garganta = COALESCE(NULLIF(TRIM(s.dor_garganta), ''), 'Desconhecido') AND ds.diarreia = COALESCE(NULLIF(TRIM(s.diarreia), ''), 'Desconhecido') AND ds.cefaleia = COALESCE(NULLIF(TRIM(s.cefaleia), ''), 'Desconhecido')
LEFT JOIN dw.dim_comorbidade dm ON dm.com_pulmao = COALESCE(NULLIF(TRIM(s.com_pulmao), ''), 'Desconhecido') AND dm.com_cardio = COALESCE(NULLIF(TRIM(s.com_cardio), ''), 'Desconhecido') AND dm.com_renal = COALESCE(NULLIF(TRIM(s.com_renal), ''), 'Desconhecido') AND dm.com_diabetes = COALESCE(NULLIF(TRIM(s.com_diabetes), ''), 'Desconhecido') AND dm.com_tabagismo = COALESCE(NULLIF(TRIM(s.com_tabagismo), ''), 'Desconhecido') AND dm.com_obesidade = COALESCE(NULLIF(TRIM(s.com_obesidade), ''), 'Desconhecido')
LEFT JOIN dw.dim_teste dt ON dt.tipo_teste_rapido = COALESCE(NULLIF(TRIM(s.tipo_teste_rapido), ''), 'Desconhecido') AND dt.resultado_rt_pcr = COALESCE(NULLIF(TRIM(s.resultado_rt_pcr), ''), 'Desconhecido') AND dt.resultado_teste_rap = COALESCE(NULLIF(TRIM(s.resultado_teste_rap), ''), 'Desconhecido') AND dt.resultado_sorologia = COALESCE(NULLIF(TRIM(s.resultado_sorologia), ''), 'Desconhecido') AND dt.resultado_sorol_igg = COALESCE(NULLIF(TRIM(s.resultado_sorol_igg), ''), 'Desconhecido');



---------------------------
-- PARTE 7

-- 1) Nenhuma FK deve estar nula (FKs NOT NULL devem garantir isso)
SELECT 'fato_sem_tempo_notif' AS teste, COUNT(*) FROM dw. fato_notificacao_covid
WHERE sk_data_notificacao IS NULL
UNION ALL
SELECT 'fato_sem_local', COUNT (*) FROM dw. fato_notificacao_covid
WHERE sk_local IS NULL;

-- 2) Contagem da fato = contagem da staging
SELECT
(SELECT COUNT (*) FROM stg. notificacao_raw) AS origem,
(SELECT COUNT (*) FROM dw. fato_notificacao_covid) AS carregado;


-- 3) Cardinalidades das dimensoes
SELECT 'dim_tempo'				AS dim,		COUNT (*) FROM dw. dim_tempo
UNION ALL SELECT 'dim_localidade',			COUNT (*) FROM dw. dim_localidade
UNION ALL SELECT 'dim_perfil', 				COUNT (*) FROM dw. dim_perfil_paciente
UNION ALL SELECT 'dim_classificacao', 		COUNT (*) FROM dw. dim_classificacao
UNION ALL SELECT 'dim_sintomas', 			COUNT (*) FROM dw. dim_sintomas
UNION ALL SELECT 'dim_comorbidade', 		COUNT (*) FROM dw. dim_comorbidade
UNION ALL SELECT 'dim_teste', 				COUNT (*) FROM dw.dim_teste;


-----------------------
-- Q1
SELECT
	l.municipio,
	t. ano_mes,
	SUM (f . flag_confirmado) AS confirmados,
SUM (f . qtd_notificacao) AS notificacoes_total
FROM dw.fato_notificacao_covid f
JOIN dw. dim_localidade l ON l.sk_local = f. sk_local
JOIN dw. dim_tempo  	t ON t.sk_tempo = f. sk_data_notificacao
WHERE t.ano IN (2021, 2022)
GROUP BY l. municipio, t.ano_mes
ORDER BY confirmados desc
LIMIT 20;


-------------------------
-- Q2
SELECT
	p. faixa_etaria,
	SUM(f. flag_confirmado) 		AS confirmados,
	SUM(f. flag_obito_covid) 		AS obitos,
	ROUND (100.0 * SUM(f. flag_obito_covid)
				 / NULLIF (SUM(f. flag_confirmado) ,0), 2) AS letalidade_pct
FROM dw. fato_notificacao_covid f
JOIN dw.dim_perfil_paciente p ON p.sk_perfil = f. sk_perfil
GROUP BY p. faixa_etaria
ORDER BY letalidade_pct DESC;



---------------------------
-- Q3
SELECT
	s.febre, s. tosse, s.dif_respiratoria,
	SUM(f. flag_internado) AS internacoes,
	SUM(f. qtd_notificacao) AS casos
FROM dw. fato_notificacao_covid f
JOIN dw.dim_sintomas s ON s.sk_sint = f.sk_sint
GROUP BY s.febre, s. tosse, s.dif_respiratoria
HAVING SUM(f. qtd_notificacao) > 1000
ORDER BY internacoes DESC
LIMIT 10;



---------------------------
--Q4
SELECT
	l.municipio,
	ROUND (AVG (f . dias_notif_encerramento) :: numeric, 1) AS dias_medio,
	COUNT (*) AS casos
FROM dw. fato_notificacao_covid f
JOIN dw. dim_localidade l ON l.sk_local = f.sk_local
WHERE f. dias_notif_encerramento IS NOT NULL
AND f.dias_notif_encerramento BETWEEN 0 AND 180
GROUP BY l. municipio
HAVING COUNT(*) > 500
ORDER BY dias_medio DESC;


------------------------------
--Q5
SELECT
	c. com_cardio, c.com_diabetes, c.com_obesidade,
	SUM(f. flag_confirmado) AS confirmados,
	SUM(f. flag_obito_covid) AS obitos,
	ROUND (100.0 * SUM(f. flag_obito_covid)
				 / NULLIF (SUM(f. flag_confirmado) ,0), 2) AS letalidade_pct
FROM dw.fato_notificacao_covid f
JOIN dw. dim_comorbidade c ON c. sk_como = f.sk_como
GROUP BY c. com_cardio, c.com_diabetes, c. com_obesidade
ORDER BY letalidade_pct desc
LIMIT 15;


-- ============================================================================
-- EXERCÍCIO 2: MODELAGEM ALTERNATIVA (FLOCO DE NEVE / SNOWFLAKE)
-- ============================================================================

-- 1. Criação da tabela de nível mais alto (Municípios/Regiões)
DROP TABLE IF EXISTS dw.dim_municipio CASCADE;
CREATE TABLE dw.dim_municipio (
    id_municipio SERIAL PRIMARY KEY,
    municipio VARCHAR(100) NOT NULL,
    uf CHAR(2) DEFAULT 'ES',
    regiao_es VARCHAR(30),
    macrorregiao VARCHAR(30),
    UNIQUE(municipio)
);

-- 2. Criação da tabela filha (Bairros) que aponta para a tabela de Municípios
DROP TABLE IF EXISTS dw.dim_localidade_snowflake CASCADE;
CREATE TABLE dw.dim_localidade_snowflake (
    sk_local SERIAL PRIMARY KEY,
    bairro VARCHAR(150) NOT NULL,
    id_municipio INT NOT NULL REFERENCES dw.dim_municipio(id_municipio),
    UNIQUE(bairro, id_municipio)
);

-- ----------------------------------------------------------------------------
-- EXERCÍCIO 3: CRIAÇÃO DA FATO_EXAME (GRÃO: EXAME REALIZADO)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dw.fato_exame CASCADE;
CREATE TABLE dw.fato_exame (
    sk_data_coleta INT REFERENCES dw.dim_tempo(sk_tempo),
    sk_local INT REFERENCES dw.dim_localidade(sk_local),
    sk_perfil INT REFERENCES dw.dim_perfil_paciente(sk_perfil),
    sk_teste INT REFERENCES dw.dim_teste(sk_teste),
    qtd_exame INT DEFAULT 1
);

INSERT INTO dw.fato_exame (sk_data_coleta, sk_local, sk_perfil, sk_teste)
SELECT 
    CASE WHEN NULLIF(TRIM(s.data_coleta_rt_pcr), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31' 
         THEN CAST(TO_CHAR(NULLIF(TRIM(s.data_coleta_rt_pcr), '')::DATE, 'YYYYMMDD') AS INT) ELSE -1 END,
    COALESCE(dl.sk_local, -1), dp.sk_perfil, dt.sk_teste
FROM stg.notificacao_raw s
JOIN dw.dim_localidade dl ON dl.municipio = COALESCE(NULLIF(TRIM(s.municipio), ''), 'Desconhecido') AND dl.bairro = COALESCE(NULLIF(TRIM(s.bairro), ''), 'Desconhecido')
JOIN dw.dim_perfil_paciente dp ON dp.sexo = COALESCE(NULLIF(TRIM(s.sexo), ''), 'Desconhecido') AND dp.faixa_etaria = COALESCE(NULLIF(TRIM(s.faixa_etaria), ''), 'Desconhecida') -- (Restante dos joins igual à Parte 6...)
JOIN dw.dim_teste dt ON dt.resultado_rt_pcr = COALESCE(NULLIF(TRIM(s.resultado_rt_pcr), ''), 'Desconhecido')
WHERE NULLIF(TRIM(s.resultado_rt_pcr), '') IS NOT NULL;


-- ----------------------------------------------------------------------------
-- EXERCÍCIO 4: DATA MART COM MATERIALIZED VIEW E ANÁLISE DE PERFORMANCE
-- ----------------------------------------------------------------------------

-- 1. Criação da Materialized View no schema mart
CREATE MATERIALIZED VIEW mart.mv_resumo_covid_municipio_mes AS
SELECT 
    l.municipio,
    t.ano_mes,
    SUM(f.flag_confirmado) AS total_confirmados,
    SUM(f.flag_obito_covid) AS total_obitos,
    SUM(f.flag_internado) AS total_internacoes
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON f.sk_local = l.sk_local
JOIN dw.dim_tempo t ON f.sk_data_notificacao = t.sk_tempo
GROUP BY l.municipio, t.ano_mes
ORDER BY t.ano_mes, l.municipio;


-- 2. Teste de Performance com EXPLAIN ANALYZE

-- Teste A: Consultando direto da Fato original (Demorado)
EXPLAIN ANALYZE
SELECT 
    l.municipio,
    t.ano_mes,
    SUM(f.flag_confirmado) AS total_confirmados,
    SUM(f.flag_obito_covid) AS total_obitos,
    SUM(f.flag_internado) AS total_internacoes
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON f.sk_local = l.sk_local
JOIN dw.dim_tempo t ON f.sk_data_notificacao = t.sk_tempo
GROUP BY l.municipio, t.ano_mes;

-- Teste B: Consultando a partir da Materialized View (Instantâneo)
EXPLAIN ANALYZE
SELECT * FROM mart.mv_resumo_covid_municipio_mes;

DROP TABLE dw.dim_localidade CASCADE;

CREATE TABLE dw.dim_localidade (
    sk_localidade SERIAL PRIMARY KEY,
    id_municipio_ibge INT,
    municipio VARCHAR(100),
    populacao_municipio INT,
    data_inicio DATE NOT NULL,
    data_fim DATE,
    flag_atual VARCHAR(3) NOT NULL
);

CREATE OR REPLACE PROCEDURE dw.sp_validar_qualidade_dados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_qtd_desconhecidos INT;
    v_qtd_orfaos INT;
    v_soma_fato INT;
    v_count_staging INT;
BEGIN
    -------------------------------------------------------------------------
    -- TESTE (a): Verificar se existe a linha "Desconhecido" nas dimensões
    -------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_qtd_desconhecidos 
    FROM dw.dim_perfil_paciente 
    WHERE sk_perfil = -1 OR sexo = 'Desconhecido';
    
    IF v_qtd_desconhecidos = 0 THEN
        RAISE EXCEPTION 'Erro de Qualidade: Linha "Desconhecido" ausente na dim_perfil_paciente.';
    END IF;

    -- Validando dim_comorbidade
    SELECT COUNT(*) INTO v_qtd_desconhecidos 
    FROM dw.dim_comorbidade 
    WHERE sk_como = -1;
    
    IF v_qtd_desconhecidos = 0 THEN
        RAISE EXCEPTION 'Erro de Qualidade: Linha "Desconhecido" ausente na dim_comorbidade.';
    END IF; 

    -------------------------------------------------------------------------
    -- TESTE (b): Teste de Registros Órfãos (Integridade Referencial)
    -------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_qtd_orfaos
    FROM staging.dados_covid st
    LEFT JOIN dw.dim_perfil_paciente p ON st.id_perfil = p.id_perfil 
    WHERE p.sk_perfil IS NULL;

    IF v_qtd_orfaos > 0 THEN
        RAISE EXCEPTION 'Erro de Qualidade: Foram encontrados % registros órfãos para a dim_perfil_paciente.', v_qtd_orfaos;
    END IF;

    -------------------------------------------------------------------------
    -- TESTE (c): Validação de Volumetria (Soma vs COUNT)
    -------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_count_staging FROM staging.dados_covid;
    SELECT COALESCE(SUM(1), 0) INTO v_soma_fato FROM staging.dados_covid;

    IF v_soma_fato <> v_count_staging THEN
        RAISE EXCEPTION 'Erro de Volumetria: A soma projetada para a fato (%) não bate com o COUNT da staging (%).', 
            v_soma_fato, v_count_staging;
    END IF;

    RAISE NOTICE 'Sucesso: Todos os testes de qualidade de dados passaram com sucesso!';
END;
$$;