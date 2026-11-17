CREATE TABLE resultado_ml (
    idresultado_ml SERIAL PRIMARY KEY,

    -- Chave estrangeira para o item
    itens_processo_iditens_processo INTEGER NOT NULL UNIQUE
        REFERENCES itens_processo(iditens_processo)
        ON DELETE CASCADE,

    -- 1. Z-Score
    zscore_preco NUMERIC(18,6),
    anomalia_zscore BOOLEAN,

    -- 2. K-Means
    cluster_kmeans INTEGER,
    anomalia_kmeans BOOLEAN NOT NULL DEFAULT FALSE,

    -- 3. Isolation Forest
    score_anomalia_iforest NUMERIC(18,6),
    anomalia_iforest BOOLEAN NOT NULL DEFAULT FALSE,

    -- 4. DBSCAN
    cluster_dbscan INTEGER,
    anomalia_dbscan BOOLEAN NOT NULL DEFAULT FALSE,

    -- Auditoria
    data_execucao TIMESTAMPTZ NOT NULL DEFAULT NOW()
);