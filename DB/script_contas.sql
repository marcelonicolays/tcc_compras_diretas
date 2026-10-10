-- ============================================================================
-- BANCO: Análise de Compras Diretas do Estado do Rio de Janeiro
-- SGBD: PostgreSQL 14+
-- Descrição: Schema normalizado para dados abertos do TCE-RJ.
--            FKs são NULLABLE quando o dado pode estar ausente na origem.
--            Dimensões pequenas têm UNIQUE para garantir integridade na carga.
-- ============================================================================


-- ============================================================================
-- 1. DIMENSÕES INDEPENDENTES
-- ============================================================================

CREATE TABLE tipo_contratacao (
    idtipo_contratacao  SERIAL       NOT NULL,
    descricao           VARCHAR(50)  NOT NULL,
    PRIMARY KEY (idtipo_contratacao),
    CONSTRAINT uq_tipo_contratacao_descricao UNIQUE (descricao)
);
COMMENT ON TABLE tipo_contratacao IS
    'Macro-categoria do processo (Compra Direta, Licitação, etc.).';


CREATE TABLE uf (
    iduf         SERIAL      NOT NULL,
    uf           VARCHAR(2)  NOT NULL,
    nome_estado  VARCHAR(40),
    PRIMARY KEY (iduf),
    CONSTRAINT uq_uf_sigla UNIQUE (uf)
);


CREATE TABLE natureza_juridica (
    idnatureza_juridica  SERIAL       NOT NULL,
    natureza             VARCHAR(100) NOT NULL,
    PRIMARY KEY (idnatureza_juridica),
    CONSTRAINT uq_natureza_juridica UNIQUE (natureza)
);


CREATE TABLE poder (
    idpoder  SERIAL      NOT NULL,
    poder    VARCHAR(20) NOT NULL,
    PRIMARY KEY (idpoder),
    CONSTRAINT uq_poder UNIQUE (poder)
);


CREATE TABLE esfera (
    idesfera  SERIAL      NOT NULL,
    esfera    VARCHAR(20) NOT NULL,
    PRIMARY KEY (idesfera),
    CONSTRAINT uq_esfera UNIQUE (esfera)
);


CREATE TABLE categoria_item (
    idcategoria_item  SERIAL       NOT NULL,
    descricao         VARCHAR(100) NOT NULL,
    PRIMARY KEY (idcategoria_item),
    CONSTRAINT uq_categoria_item UNIQUE (descricao)
);


CREATE TABLE afastamento (
    idafastamento          SERIAL       NOT NULL,
    descricao_afastamento  VARCHAR(100),
    PRIMARY KEY (idafastamento)
);
COMMENT ON TABLE afastamento IS
    'Modalidade de afastamento do rito licitatório (Dispensa, Inexigibilidade). '
    'Sem UNIQUE porque a origem pode trazer variações textuais da mesma modalidade.';


CREATE TABLE un_medida (
    idun_medida  SERIAL      NOT NULL,
    un_medida    VARCHAR(20),
    PRIMARY KEY (idun_medida),
    CONSTRAINT uq_un_medida UNIQUE (un_medida)
);


CREATE TABLE cnae (
    id_cnae    SERIAL      NOT NULL,
    cnae       VARCHAR(10),
    descricao  VARCHAR(200),
    PRIMARY KEY (id_cnae),
    CONSTRAINT uq_cnae UNIQUE (cnae)
);


CREATE TABLE situacao_processo (
    idsituacao_processo  SERIAL       NOT NULL,
    descricao            VARCHAR(50)  NOT NULL,
    PRIMARY KEY (idsituacao_processo),
    CONSTRAINT uq_situacao_processo UNIQUE (descricao)
);


-- ============================================================================
-- 2. DIMENSÕES DEPENDENTES
-- ============================================================================

CREATE TABLE municipio (
    idmunicipio  SERIAL       NOT NULL,
    uf_iduf      INTEGER      NOT NULL,
    municipio    VARCHAR(50)  NOT NULL,
    PRIMARY KEY (idmunicipio),
    CONSTRAINT uq_municipio_uf UNIQUE (municipio, uf_iduf),
    FOREIGN KEY (uf_iduf) REFERENCES uf(iduf)
);
CREATE INDEX idx_municipio_uf ON municipio (uf_iduf);


-- ============================================================================
-- 3. ENDEREÇO (decomposto — atende 1FN)
-- ============================================================================

CREATE TABLE endereco (
    idendereco             SERIAL        NOT NULL,
    municipio_idmunicipio  INTEGER       NOT NULL,
    logradouro             VARCHAR(150),
    numero                 VARCHAR(20),
    complemento            VARCHAR(100),
    bairro                 VARCHAR(100),
    cep                    CHAR(8),
    PRIMARY KEY (idendereco),
    FOREIGN KEY (municipio_idmunicipio) REFERENCES municipio(idmunicipio)
);
CREATE INDEX idx_endereco_municipio ON endereco (municipio_idmunicipio);
CREATE INDEX idx_endereco_cep ON endereco (cep);
COMMENT ON TABLE endereco IS
    'Endereço decomposto (1FN). Campos textuais são NULLABLE pois a origem pode não fornecer todos.';


-- ============================================================================
-- 4. FORNECEDOR (supertype / subtype)
-- ============================================================================

CREATE TABLE fornecedor (
    idfornecedor         SERIAL   NOT NULL,
    endereco_idendereco  INTEGER,
    PRIMARY KEY (idfornecedor),
    FOREIGN KEY (endereco_idendereco) REFERENCES endereco(idendereco)
);
COMMENT ON TABLE fornecedor IS
    'Supertype de fornecedor (PF ou PJ). Endereço é opcional pois pode faltar na origem.';


CREATE TABLE fornecedor_pf (
    idfornecedor_pf         SERIAL        NOT NULL,
    fornecedor_idfornecedor INTEGER       NOT NULL,
    cpf                     VARCHAR(14),
    nome                    VARCHAR(200),
    data_nascimento         DATE,
    nome_mae                VARCHAR(200),
    nome_pai                VARCHAR(200),
    PRIMARY KEY (idfornecedor_pf),
    FOREIGN KEY (fornecedor_idfornecedor) REFERENCES fornecedor(idfornecedor)
);
CREATE INDEX idx_fornecedor_pf_fk ON fornecedor_pf (fornecedor_idfornecedor);
CREATE UNIQUE INDEX uq_fornecedor_pf_cpf
    ON fornecedor_pf (cpf) WHERE cpf IS NOT NULL;


CREATE TABLE fornecedor_pj (
    idfornecedor_pj                       SERIAL        NOT NULL,
    natureza_juridica_idnatureza_juridica INTEGER,
    fornecedor_idfornecedor               INTEGER       NOT NULL,
    cnpj                                  CHAR(14),
    razao_social                          VARCHAR(200),
    nome_fantasia                         VARCHAR(200),
    data_inicio                           DATE,
    PRIMARY KEY (idfornecedor_pj),
    FOREIGN KEY (fornecedor_idfornecedor) REFERENCES fornecedor(idfornecedor),
    FOREIGN KEY (natureza_juridica_idnatureza_juridica) REFERENCES natureza_juridica(idnatureza_juridica)
);
CREATE INDEX idx_fornecedor_pj_fk ON fornecedor_pj (fornecedor_idfornecedor);
CREATE INDEX idx_fornecedor_pj_natjur ON fornecedor_pj (natureza_juridica_idnatureza_juridica);
CREATE UNIQUE INDEX uq_fornecedor_pj_cnpj
    ON fornecedor_pj (cnpj) WHERE cnpj IS NOT NULL;


CREATE TABLE cnae_fornecedor (
    idcnae_fornecedor              SERIAL   NOT NULL,
    fornecedor_pj_idfornecedor_pj  INTEGER  NOT NULL,
    cnae_id_cnae                   INTEGER  NOT NULL,
    principal                      BOOL     NOT NULL DEFAULT FALSE,
    PRIMARY KEY (idcnae_fornecedor),
    CONSTRAINT uq_cnae_fornecedor UNIQUE (fornecedor_pj_idfornecedor_pj, cnae_id_cnae),
    FOREIGN KEY (cnae_id_cnae) REFERENCES cnae(id_cnae),
    FOREIGN KEY (fornecedor_pj_idfornecedor_pj) REFERENCES fornecedor_pj(idfornecedor_pj)
);
CREATE INDEX idx_cnae_forn_pj ON cnae_fornecedor (fornecedor_pj_idfornecedor_pj);
CREATE INDEX idx_cnae_forn_cnae ON cnae_fornecedor (cnae_id_cnae);


-- View unificada (útil no ML e no Power BI)
CREATE OR REPLACE VIEW vw_fornecedor AS
SELECT
    f.idfornecedor,
    COALESCE(pj.razao_social, pf.nome) AS nome,
    pj.cnpj,
    pf.cpf,
    CASE WHEN pj.idfornecedor_pj IS NOT NULL THEN 'PJ' ELSE 'PF' END AS tipo_pessoa,
    e.logradouro, e.numero, e.bairro, e.cep,
    m.municipio, u.uf
FROM fornecedor f
LEFT JOIN fornecedor_pj pj ON pj.fornecedor_idfornecedor = f.idfornecedor
LEFT JOIN fornecedor_pf pf ON pf.fornecedor_idfornecedor = f.idfornecedor
LEFT JOIN endereco e ON e.idendereco = f.endereco_idendereco
LEFT JOIN municipio m ON m.idmunicipio = e.municipio_idmunicipio
LEFT JOIN uf u ON u.iduf = m.uf_iduf;
COMMENT ON VIEW vw_fornecedor IS
    'Unifica PF/PJ com nome resolvido e endereço achatado.';


-- ============================================================================
-- 5. ÓRGÃO (supertype / subtype)
-- ============================================================================

CREATE TABLE orgao (
    idorgao          SERIAL        NOT NULL,
    poder_idpoder    INTEGER,
    esfera_idesfera  INTEGER,
    nome_orgao       VARCHAR(200)  NOT NULL,
    sigla            VARCHAR(30),
    ativo            BOOL          DEFAULT TRUE,
    PRIMARY KEY (idorgao),
    FOREIGN KEY (esfera_idesfera) REFERENCES esfera(idesfera),
    FOREIGN KEY (poder_idpoder) REFERENCES poder(idpoder)
);
CREATE INDEX idx_orgao_poder ON orgao (poder_idpoder);
CREATE INDEX idx_orgao_esfera ON orgao (esfera_idesfera);
CREATE INDEX idx_orgao_nome ON orgao (nome_orgao);


CREATE TABLE orgao_municipal (
    idorgao_municipal      SERIAL   NOT NULL,
    municipio_idmunicipio  INTEGER  NOT NULL,
    orgao_idorgao          INTEGER  NOT NULL,
    PRIMARY KEY (idorgao_municipal),
    CONSTRAINT uq_orgao_municipal UNIQUE (orgao_idorgao),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (municipio_idmunicipio) REFERENCES municipio(idmunicipio)
);


CREATE TABLE orgao_estadual (
    idorgao_estadual  SERIAL   NOT NULL,
    uf_iduf           INTEGER  NOT NULL,
    orgao_idorgao     INTEGER  NOT NULL,
    PRIMARY KEY (idorgao_estadual),
    CONSTRAINT uq_orgao_estadual UNIQUE (orgao_idorgao),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (uf_iduf) REFERENCES uf(iduf)
);


-- ============================================================================
-- 6. ITEM
-- ============================================================================

CREATE TABLE item (
    iditem                          SERIAL        NOT NULL,
    categoria_item_idcategoria_item INTEGER,
    un_medida_idun_medida           INTEGER,
    descricao_item                  VARCHAR(200)  NOT NULL,
    PRIMARY KEY (iditem),
    FOREIGN KEY (un_medida_idun_medida) REFERENCES un_medida(idun_medida),
    FOREIGN KEY (categoria_item_idcategoria_item) REFERENCES categoria_item(idcategoria_item)
);
CREATE INDEX idx_item_categoria ON item (categoria_item_idcategoria_item);
CREATE INDEX idx_item_un_medida ON item (un_medida_idun_medida);
COMMENT ON COLUMN item.descricao_item IS
    'Texto livre, sem padronização imposta. A origem TCE-RJ traz variações textuais.';


-- ============================================================================
-- 7. PROCESSO
-- ============================================================================

CREATE TABLE processo (
    idprocesso                            SERIAL        NOT NULL,
    tipo_contratacao_idtipo_contratacao   INTEGER,
    orgao_idorgao                         INTEGER,
    fornecedor_idfornecedor               INTEGER,
    situacao_processo_idsituacao          INTEGER,
    numero_processo                       VARCHAR(60),
    valor_processo                        NUMERIC(18,2),
    objeto                                VARCHAR(200),
    ano_processo                          INTEGER,
    data_aprovacao                        DATE,
    enquadramento                         VARCHAR(200),
    hash_origem                           CHAR(64),
    created_at                            TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (idprocesso),
    FOREIGN KEY (fornecedor_idfornecedor) REFERENCES fornecedor(idfornecedor),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (tipo_contratacao_idtipo_contratacao) REFERENCES tipo_contratacao(idtipo_contratacao),
    FOREIGN KEY (situacao_processo_idsituacao) REFERENCES situacao_processo(idsituacao_processo)
);

-- Índices para consultas analíticas
CREATE INDEX idx_processo_fornecedor ON processo (fornecedor_idfornecedor);
CREATE INDEX idx_processo_orgao ON processo (orgao_idorgao);
CREATE INDEX idx_processo_tipo ON processo (tipo_contratacao_idtipo_contratacao);
CREATE INDEX idx_processo_ano ON processo (ano_processo);
CREATE INDEX idx_processo_data ON processo (data_aprovacao);
CREATE INDEX idx_processo_valor ON processo (valor_processo);

COMMENT ON COLUMN processo.valor_processo IS
    'Redundância controlada em relação à soma de itens_processo. '
    'Mantido por fidelidade à fonte (TCE-RJ) e para validação cruzada.';
COMMENT ON COLUMN processo.enquadramento IS
    'Texto livre limitado a 200 caracteres. A base do TCE-RJ apresenta alta '
    'heterogeneidade, impedindo decomposição em atributos estruturados.';
COMMENT ON COLUMN processo.numero_processo IS
    'NULLABLE pois a origem pode trazer processos sem numeração formal.';


-- ============================================================================
-- 8. PROCESSO COMPRA DIRETA (subtype 1:1)
-- ============================================================================

CREATE TABLE processo_compra_direta (
    idprocesso_compra_direta   SERIAL   NOT NULL,
    afastamento_idafastamento  INTEGER,
    processo_idprocesso        INTEGER  NOT NULL,
    PRIMARY KEY (idprocesso_compra_direta),
    CONSTRAINT uq_processo_compra_direta UNIQUE (processo_idprocesso),
    FOREIGN KEY (processo_idprocesso) REFERENCES processo(idprocesso) ON DELETE CASCADE,
    FOREIGN KEY (afastamento_idafastamento) REFERENCES afastamento(idafastamento)
);
CREATE INDEX idx_pcd_processo ON processo_compra_direta (processo_idprocesso);
CREATE INDEX idx_pcd_afastamento ON processo_compra_direta (afastamento_idafastamento);


-- ============================================================================
-- 9. ITENS DO PROCESSO
-- ============================================================================

CREATE TABLE itens_processo (
    iditens_processo     SERIAL         NOT NULL,
    processo_idprocesso  INTEGER        NOT NULL,
    item_iditem          INTEGER        NOT NULL,
    quantidade           NUMERIC(18,4),
    valor_unitario       NUMERIC(18,4),
    valor_total          NUMERIC(18,2),
    marca                VARCHAR(100),
    created_at           TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (iditens_processo),
    FOREIGN KEY (item_iditem) REFERENCES item(iditem),
    FOREIGN KEY (processo_idprocesso) REFERENCES processo(idprocesso) ON DELETE CASCADE,
    CONSTRAINT uq_itens_processo UNIQUE (processo_idprocesso, item_iditem)
);
CREATE INDEX idx_itens_processo ON itens_processo (processo_idprocesso);
CREATE INDEX idx_itens_item ON itens_processo (item_iditem);
CREATE INDEX idx_itens_valor_unit ON itens_processo (valor_unitario);
CREATE INDEX idx_itens_quantidade ON itens_processo (quantidade);
COMMENT ON COLUMN itens_processo.valor_total IS
    'Coluna opcional. Pode ser calculada como quantidade * valor_unitario, '
    'mas mantida quando a fonte traz valor divergente por desconto ou arredondamento.';


-- ============================================================================
-- 10. LOG DE CARGA (rastreabilidade / reprodutibilidade)
-- ============================================================================

CREATE TABLE log_carga (
    idlog                SERIAL        NOT NULL,
    arquivo_origem       VARCHAR(300),
    hash_arquivo         CHAR(64),
    data_carga           TIMESTAMP DEFAULT NOW(),
    linhas_lidas         INTEGER,
    linhas_inseridas     INTEGER,
    linhas_rejeitadas    INTEGER,
    observacoes          VARCHAR(200),
    PRIMARY KEY (idlog)
);
COMMENT ON TABLE log_carga IS
    'Registra cada execução do pipeline de ingestão para rastreabilidade acadêmica.';


-- ============================================================================
-- 11. VIEW MATERIALIZADA COM FEATURES PARA ML
-- ============================================================================

CREATE MATERIALIZED VIEW mv_features_ml AS
SELECT
    ip.iditens_processo,
    p.idprocesso,
    o.idorgao,
    f.idfornecedor,
    i.iditem,
    ci.idcategoria_item,
    um.idun_medida,
    a.idafastamento,
    p.ano_processo,
    p.valor_processo,
    ip.quantidade,
    ip.valor_unitario,
    LOG(1 + GREATEST(ip.valor_unitario, 0)) AS log_valor_unitario,
    LOG(1 + GREATEST(p.valor_processo, 0))  AS log_valor_processo,
    LOG(1 + GREATEST(ip.quantidade, 0))     AS log_quantidade,
    CASE
        WHEN p.valor_processo > 0
        THEN (ip.quantidade * ip.valor_unitario) / p.valor_processo
        ELSE NULL
    END AS proporcao_item_processo
FROM itens_processo ip
JOIN processo p ON p.idprocesso = ip.processo_idprocesso
LEFT JOIN orgao o ON o.idorgao = p.orgao_idorgao
LEFT JOIN fornecedor f ON f.idfornecedor = p.fornecedor_idfornecedor
LEFT JOIN item i ON i.iditem = ip.item_iditem
LEFT JOIN categoria_item ci ON ci.idcategoria_item = i.categoria_item_idcategoria_item
LEFT JOIN un_medida um ON um.idun_medida = i.un_medida_idun_medida
LEFT JOIN processo_compra_direta pcd ON pcd.processo_idprocesso = p.idprocesso
LEFT JOIN afastamento a ON a.idafastamento = pcd.afastamento_idafastamento
WHERE ip.quantidade IS NOT NULL
  AND ip.valor_unitario IS NOT NULL;

CREATE INDEX idx_mv_features_orgao ON mv_features_ml (idorgao);
CREATE INDEX idx_mv_features_fornecedor ON mv_features_ml (idfornecedor);
CREATE INDEX idx_mv_features_categoria ON mv_features_ml (idcategoria_item);
CREATE INDEX idx_mv_features_ano ON mv_features_ml (ano_processo);

COMMENT ON MATERIALIZED VIEW mv_features_ml IS
    'Matriz de features pronta para K-Means e Isolation Forest. '
    'Recriar com REFRESH MATERIALIZED VIEW após cada carga.';


-- ============================================================================
-- 12. SEED DE DIMENSÕES
-- ============================================================================

INSERT INTO tipo_contratacao (descricao) VALUES
    ('Compra Direta'),
    ('Licitação'),
    ('Adesão a Ata'),
    ('Credenciamento');

INSERT INTO uf (uf, nome_estado) VALUES
    ('RJ', 'Rio de Janeiro'),
    ('SP', 'São Paulo'),
    ('MG', 'Minas Gerais'),
    ('ES', 'Espírito Santo'),
    ('DF', 'Distrito Federal');

INSERT INTO poder (poder) VALUES
    ('Executivo'),
    ('Legislativo'),
    ('Judiciário');

INSERT INTO esfera (esfera) VALUES
    ('Federal'),
    ('Estadual'),
    ('Municipal'),
    ('Distrital');

INSERT INTO situacao_processo (descricao) VALUES
    ('Em andamento'),
    ('Homologado'),
    ('Cancelado'),
    ('Fracassado'),
    ('Deserto');

INSERT INTO afastamento (descricao_afastamento) VALUES
    ('Dispensa - Pequenas Compras'),
    ('Dispensa - Emergencial'),
    ('Dispensa - Licitação Desertificada'),
    ('Inexigibilidade - 14.133/2021'),
    ('Inexigibilidade - 8.666/93');

INSERT INTO categoria_item (descricao) VALUES
    ('Material de Escritório'),
    ('Medicamentos'),
    ('Material Hospitalar'),
    ('Tecnologia da Informação'),
    ('Obras e Serviços de Engenharia'),
    ('Serviços Continuados'),
    ('Fornecimento de Água'),
    ('Manutenção Predial'),
    ('Serviços de Limpeza'),
    ('Outros');

INSERT INTO un_medida (un_medida) VALUES
    ('UN'), ('CX'), ('KG'), ('L'), ('M'), ('M2'), ('M3'),
    ('SERVICO'), ('PACOTE'), ('FRASCO'), ('CAIXA');


-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================