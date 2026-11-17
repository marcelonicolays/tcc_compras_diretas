-- ============================================================================
-- BANCO: Análise de Compras Diretas do Estado do Rio de Janeiro
-- SGBD: PostgreSQL 14+
-- Descrição: Schema normalizado (3FN) para dados abertos do TCE-RJ.
--            FKs NULLABLE quando o dado pode estar ausente na origem.
-- ============================================================================


-- Garantir schema public no supabase

SET search_path TO public;


-- ============================================================================
-- 1. DIMENSÕES INDEPENDENTES
-- ============================================================================

CREATE TABLE tipo_contratacao (
    idtipo_contratacao  SERIAL       NOT NULL,
    descricao           VARCHAR(30)  NOT NULL,
    PRIMARY KEY (idtipo_contratacao),
    CONSTRAINT uq_tipo_contratacao UNIQUE (descricao)
);


CREATE TABLE uf (
    iduf         SERIAL       NOT NULL,
    uf           VARCHAR(2)   NOT NULL,
    nome_estado  VARCHAR(40),
    PRIMARY KEY (iduf),
    CONSTRAINT uq_uf UNIQUE (uf)
);


CREATE TABLE natureza_juridica (
    idnatureza_juridica  SERIAL       NOT NULL,
    natureza             VARCHAR(100) NOT NULL,
    PRIMARY KEY (idnatureza_juridica),
    CONSTRAINT uq_natureza_juridica UNIQUE (natureza)
);


CREATE TABLE poder (
    idpoder  SERIAL       NOT NULL,
    poder    VARCHAR(20)  NOT NULL,
    PRIMARY KEY (idpoder),
    CONSTRAINT uq_poder UNIQUE (poder)
);


CREATE TABLE esfera (
    idesfera  SERIAL       NOT NULL,
    esfera    VARCHAR(20)  NOT NULL,
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
    descricao_afastamento  VARCHAR(50),
    PRIMARY KEY (idafastamento)
);
COMMENT ON TABLE afastamento IS
    'Sem UNIQUE porque a origem pode trazer variações textuais da mesma modalidade.';


CREATE TABLE un_medida (
    idun_medida  SERIAL       NOT NULL,
    un_medida    VARCHAR(20),
    PRIMARY KEY (idun_medida),
    CONSTRAINT uq_un_medida UNIQUE (un_medida)
);


CREATE TABLE cnae (
    id_cnae    SERIAL       NOT NULL,
    cnae       VARCHAR(10),
    descricao  VARCHAR(200),
    PRIMARY KEY (id_cnae),
    CONSTRAINT uq_cnae UNIQUE (cnae)
);


-- ============================================================================
-- 2. DIMENSÕES DEPENDENTES
-- ============================================================================

CREATE TABLE municipio (
    idmunicipio  SERIAL       NOT NULL,
    uf_iduf      INTEGER      NOT NULL,
    municipio    VARCHAR(50)  NOT NULL,
    PRIMARY KEY (idmunicipio),
    CONSTRAINT uq_municipio UNIQUE (municipio, uf_iduf),
    FOREIGN KEY (uf_iduf) REFERENCES uf(iduf)
);
CREATE INDEX municipio_FKIndex1 ON municipio (uf_iduf);
CREATE INDEX IFK_Rel_01 ON municipio (uf_iduf);


CREATE TABLE cep (
    cep                    VARCHAR(8)  NOT NULL,
    municipio_idmunicipio  INTEGER     NOT NULL,
    PRIMARY KEY (cep),
    FOREIGN KEY (municipio_idmunicipio) REFERENCES municipio(idmunicipio)
);
CREATE INDEX cep_FKIndex1 ON cep (municipio_idmunicipio);
COMMENT ON TABLE cep IS
    'Cada CEP pertence a um único município, eliminando a dependência '
    'transitiva parte → cep → município. CEP sem máscara (8 dígitos).';


-- ============================================================================
-- 3. PARTE (supertype) — cobre fornecedores, sócios e demais atores
-- ============================================================================

CREATE TABLE parte (
    idparte       SERIAL       NOT NULL,
    cep           VARCHAR(8),
    tipo_pessoa   VARCHAR(2)   NOT NULL,
    logradouro    VARCHAR(150),
    numero        VARCHAR(20),
    complemento   VARCHAR(100),
    bairro        VARCHAR(100),
    PRIMARY KEY (idparte),
    CONSTRAINT chk_parte_tipo_pessoa CHECK (tipo_pessoa IN ('PF', 'PJ')),
    FOREIGN KEY (cep) REFERENCES cep(cep)
);
CREATE INDEX parte_FKIndex1 ON parte (cep);
COMMENT ON TABLE parte IS
    'Supertipo que representa qualquer pessoa (física ou jurídica) que se '
    'relaciona com a administração pública: fornecedores, sócios, etc.';
COMMENT ON COLUMN parte.cep IS
    'FK para cep. NULLABLE: a fonte pode não fornecer CEP. Município é obtido '
    'via JOIN com cep → municipio.';
COMMENT ON COLUMN parte.logradouro IS
    'Endereço decomposto (1FN). Campos textuais NULLABLE pois a origem pode não fornecer.';
COMMENT ON COLUMN parte.tipo_pessoa IS
    'Discriminador PF/PJ. Redundância controlada em relação à presença em '
    'parte_pf ou parte_pj, mantido para simplificar filtros e relatórios.';


CREATE TABLE parte_pf (
    idparte_pf       SERIAL       NOT NULL,
    parte_idparte    INTEGER      NOT NULL,
    cpf              VARCHAR(14),
    nome             VARCHAR(200),
    data_nascimento  DATE,
    nome_maie        VARCHAR(200),
    nome_pai         VARCHAR(200),
    PRIMARY KEY (idparte_pf),
    CONSTRAINT uq_parte_pf UNIQUE (parte_idparte),
    FOREIGN KEY (parte_idparte) REFERENCES parte(idparte)
);
CREATE INDEX parte_pf_FKIndex1 ON parte_pf (parte_idparte);
CREATE UNIQUE INDEX uq_parte_pf_cpf
    ON parte_pf (cpf) WHERE cpf IS NOT NULL;


CREATE TABLE parte_pj (
    idparte_pj                            SERIAL       NOT NULL,
    natureza_juridica_idnatureza_juridica INTEGER      NOT NULL,
    parte_idparte                         INTEGER      NOT NULL,
    cnpj                                  CHAR(14),
    razao_social                          VARCHAR(200),
    nome_fantasia                         VARCHAR(200),
    data_inicio                           DATE,
    PRIMARY KEY (idparte_pj),
    CONSTRAINT uq_parte_pj UNIQUE (parte_idparte),
    FOREIGN KEY (parte_idparte) REFERENCES parte(idparte),
    FOREIGN KEY (natureza_juridica_idnatureza_juridica) REFERENCES natureza_juridica(idnatureza_juridica)
);
CREATE INDEX parte_pj_FKIndex1 ON parte_pj (parte_idparte);
CREATE INDEX parte_pj_FKIndex2 ON parte_pj (natureza_juridica_idnatureza_juridica);
CREATE UNIQUE INDEX uq_parte_pj_cnpj
    ON parte_pj (cnpj) WHERE cnpj IS NOT NULL;
COMMENT ON TABLE parte_pj IS
    'O identificador (CNPJ) fica no subtipo, e não no supertype, por escolha de '
    'modelagem que preserva a semântica PF/PJ. Documentado como decisão consciente.';


CREATE TABLE cnae_parte (
    idcnae_parte         SERIAL   NOT NULL,
    parte_pj_idparte_pj  INTEGER  NOT NULL,
    cnae_id_cnae         INTEGER  NOT NULL,
    principal            BOOL     NOT NULL,
    PRIMARY KEY (idcnae_parte),
    CONSTRAINT uq_cnae_parte UNIQUE (parte_pj_idparte_pj, cnae_id_cnae),
    FOREIGN KEY (cnae_id_cnae) REFERENCES cnae(id_cnae),
    FOREIGN KEY (parte_pj_idparte_pj) REFERENCES parte_pj(idparte_pj)
);
CREATE INDEX cnae_parte_FKIndex1 ON cnae_parte (cnae_id_cnae);
CREATE INDEX cnae_parte_FKIndex2 ON cnae_parte (parte_pj_idparte_pj);


-- ============================================================================
-- 4. SÓCIO — relação N:N entre partes (sócio ↔ empresa)
-- ============================================================================

CREATE TABLE socio (
    idsocio                  SERIAL        NOT NULL,
    parte_idparte_socio      INTEGER       NOT NULL,
    parte_pj_idparte_pj      INTEGER       NOT NULL,
    data_inicio              DATE,
    data_fim                 DATE,
    percentual_participacao  NUMERIC(5,2),
    PRIMARY KEY (idsocio),
    CONSTRAINT uq_socio UNIQUE (parte_pj_idparte_pj, parte_idparte_socio),
    CONSTRAINT chk_socio_distinto CHECK (parte_idparte_socio <> parte_pj_idparte_pj),
    FOREIGN KEY (parte_idparte_socio) REFERENCES parte(idparte),
    FOREIGN KEY (parte_pj_idparte_pj) REFERENCES parte_pj(idparte_pj)
);
CREATE INDEX socio_FKIndex1 ON socio (parte_idparte_socio);
CREATE INDEX socio_FKIndex2 ON socio (parte_pj_idparte_pj);
COMMENT ON TABLE socio IS
    'Quadro societário. Um sócio (PF ou PJ) participa de uma ou mais empresas (PJ). '
    'Permite identificar sócios em comum entre fornecedores, padrão clássico de conluio.';
COMMENT ON COLUMN socio.percentual_participacao IS
    'Percentual de participação (0.00 a 100.00). NULLABLE: a fonte pode não informar.';


-- ============================================================================
-- 5. ÓRGÃO (supertype / subtype)
-- ============================================================================

CREATE TABLE orgao (
    idorgao          SERIAL       NOT NULL,
    poder_idpoder    INTEGER,
    esfera_idesfera  INTEGER,
    nome_orgao       VARCHAR(200) NOT NULL,
    ativo            BOOL,
    PRIMARY KEY (idorgao),
    FOREIGN KEY (esfera_idesfera) REFERENCES esfera(idesfera),
    FOREIGN KEY (poder_idpoder) REFERENCES poder(idpoder)
);
CREATE INDEX orgao_FKIndex1 ON orgao (esfera_idesfera);
CREATE INDEX orgao_FKIndex2 ON orgao (poder_idpoder);
CREATE INDEX IFK_Rel_02 ON orgao (esfera_idesfera);
CREATE INDEX IFK_Rel_03 ON orgao (poder_idpoder);
COMMENT ON COLUMN orgao.poder_idpoder IS
    'NULLABLE: a fonte pode não classificar o órgão por poder.';
COMMENT ON COLUMN orgao.esfera_idesfera IS
    'NULLABLE: a fonte pode não classificar o órgão por esfera.';


CREATE TABLE orgao_municipal (
    idorgao_municipal      SERIAL   NOT NULL,
    municipio_idmunicipio  INTEGER  NOT NULL,
    orgao_idorgao          INTEGER  NOT NULL,
    PRIMARY KEY (idorgao_municipal),
    CONSTRAINT uq_orgao_municipal UNIQUE (orgao_idorgao),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (municipio_idmunicipio) REFERENCES municipio(idmunicipio)
);
CREATE INDEX orgao_municipal_FKIndex1 ON orgao_municipal (orgao_idorgao);
CREATE INDEX orgao_municipal_FKIndex2 ON orgao_municipal (municipio_idmunicipio);


CREATE TABLE orgao_estadual (
    idorgao_estadual  SERIAL   NOT NULL,
    uf_iduf           INTEGER  NOT NULL,
    orgao_idorgao     INTEGER  NOT NULL,
    PRIMARY KEY (idorgao_estadual),
    CONSTRAINT uq_orgao_estadual UNIQUE (orgao_idorgao),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (uf_iduf) REFERENCES uf(iduf)
);
CREATE INDEX orgao_estadual_FKIndex1 ON orgao_estadual (orgao_idorgao);
CREATE INDEX orgao_estadual_FKIndex2 ON orgao_estadual (uf_iduf);


-- ============================================================================
-- 6. ITEM
-- ============================================================================

CREATE TABLE item (
    iditem                          SERIAL       NOT NULL,
    categoria_item_idcategoria_item INTEGER,
    un_medida_idun_medida           INTEGER,
    descricao_item                  TEXT         NOT NULL,
    PRIMARY KEY (iditem),
    FOREIGN KEY (un_medida_idun_medida) REFERENCES un_medida(idun_medida),
    FOREIGN KEY (categoria_item_idcategoria_item) REFERENCES categoria_item(idcategoria_item)
);
CREATE INDEX item_FKIndex1 ON item (un_medida_idun_medida);
CREATE INDEX item_FKIndex2 ON item (categoria_item_idcategoria_item);


-- ============================================================================
-- 7. PROCESSO
-- ============================================================================

CREATE TABLE processo (
    idprocesso                            SERIAL        NOT NULL,
    tipo_contratacao_idtipo_contratacao   INTEGER,
    orgao_idorgao                         INTEGER,
    parte_idparte                         INTEGER,
    numero_processo                       VARCHAR(40),
    valor_processo                        NUMERIC(18,2),
    objeto                                VARCHAR(200),
    ano_processo                          INTEGER,
    data_aprovacao                        DATE,
    enquadramento                         VARCHAR(200),
    PRIMARY KEY (idprocesso),
    FOREIGN KEY (parte_idparte) REFERENCES parte(idparte),
    FOREIGN KEY (orgao_idorgao) REFERENCES orgao(idorgao),
    FOREIGN KEY (tipo_contratacao_idtipo_contratacao) REFERENCES tipo_contratacao(idtipo_contratacao)
);
CREATE INDEX processo_FKIndex1 ON processo (parte_idparte);
CREATE INDEX processo_FKIndex2 ON processo (orgao_idorgao);
CREATE INDEX processo_FKIndex3 ON processo (tipo_contratacao_idtipo_contratacao);
CREATE INDEX idx_processo_ano ON processo (ano_processo);
CREATE INDEX idx_processo_data ON processo (data_aprovacao);

COMMENT ON COLUMN processo.valor_processo IS
    'Redundância controlada em relação à soma de itens. Mantido para validação '
    'cruzada com o valor divulgado pela fonte (TCE-RJ).';
COMMENT ON COLUMN processo.ano_processo IS
    'Redundância controlada em relação a data_aprovacao. Mantido como controle '
    'para verificar divergências entre o ano declarado e a data efetiva.';


-- ============================================================================
-- 8. PROCESSO COMPRA DIRETA (subtype 1:1)
-- ============================================================================

CREATE TABLE processo_compra_direta (
    idprocesso_compra_direta   SERIAL   NOT NULL,
    afastamento_idafastamento  INTEGER,
    processo_idprocesso        INTEGER  NOT NULL,
    PRIMARY KEY (idprocesso_compra_direta),
    CONSTRAINT uq_processo_compra_direta UNIQUE (processo_idprocesso),
    FOREIGN KEY (processo_idprocesso) REFERENCES processo(idprocesso),
    FOREIGN KEY (afastamento_idafastamento) REFERENCES afastamento(idafastamento)
);
CREATE INDEX processo_compra_direta_FKIndex1 ON processo_compra_direta (processo_idprocesso);
CREATE INDEX processo_compra_direta_FKIndex2 ON processo_compra_direta (afastamento_idafastamento);


-- ============================================================================
-- 9. ITENS DO PROCESSO
-- ============================================================================

CREATE TABLE itens_processo (
    iditens_processo     SERIAL         NOT NULL,
    processo_idprocesso  INTEGER        NOT NULL,
    item_iditem          INTEGER        NOT NULL,
    quantidade           NUMERIC(18,4),
    valor_unitario       NUMERIC(18,4),
    PRIMARY KEY (iditens_processo),
    FOREIGN KEY (item_iditem) REFERENCES item(iditem),
    FOREIGN KEY (processo_idprocesso) REFERENCES processo(idprocesso)
);
CREATE INDEX itens_processo_FKIndex1 ON itens_processo (item_iditem);
CREATE INDEX itens_processo_FKIndex2 ON itens_processo (processo_idprocesso);
CREATE INDEX idx_itens_valor_unit ON itens_processo (valor_unitario);
CREATE INDEX idx_itens_quantidade ON itens_processo (quantidade);

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================