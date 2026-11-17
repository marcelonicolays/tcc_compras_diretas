# Análise de Compras Diretas do Estado do Rio de Janeiro

Projeto de Trabalho de Conclusão de Curso (TCC) em Ciência de Dados, desenvolvido na Universidade Católica de Petrópolis (UCP).

O projeto utiliza técnicas de Ciência de Dados, banco de dados relacional, aprendizado de máquina não supervisionado e Business Intelligence (BI) para analisar as compras diretas realizadas pelos órgãos da administração pública estadual do Rio de Janeiro.

O objetivo é identificar padrões de comportamento, concentração de gastos e registros com características atípicas, contribuindo para a transparência das informações públicas, o controle social e a fiscalização cidadã.

## Objetivos

- Analisar os dados de compras diretas do Estado do Rio de Janeiro.
- Construir um processo de extração, transformação e carga (ETL) para preparação e validação dos dados.
- Implementar um banco de dados relacional para armazenamento e organização das informações.
- Aplicar técnicas de aprendizado de máquina não supervisionado para identificar agrupamentos e registros potencialmente atípicos.
- Desenvolver um painel interativo no Power BI para exploração dos dados e apresentação dos resultados.
- Disponibilizar informações que auxiliem a sociedade civil na compreensão dos gastos públicos.

## Fonte de dados

Os dados utilizados são provenientes da API de Dados Abertos do Tribunal de Contas do Estado do Rio de Janeiro (TCE-RJ).

**Fonte:** [TCE-RJ – API de Compras Diretas do Estado](https://dados.tcerj.tc.br/api/v1/docs#/Estado/compras_diretas_estado_api_v1_compras_diretas_estado_get).

**Período analisado:** janeiro de 2023 a junho de 2026.

A base contempla informações sobre processos de compras diretas, órgãos contratantes, fornecedores, objetos, itens, quantidades, valores e enquadramentos legais.

## Tecnologias utilizadas

| Tecnologia | Aplicação |
|---|---|
| Python | Tratamento, análise e modelagem dos dados |
| Pandas | Manipulação e preparação dos dados |
| Scikit-learn | Implementação dos algoritmos de Machine Learning |
| Google Colab | Ambiente de desenvolvimento dos notebooks |
| PostgreSQL | Armazenamento e gerenciamento dos dados |
| Supabase | Hospedagem do banco de dados na nuvem |
| SQL | Consultas, organização e integração dos dados |
| Power BI | Análise visual e construção do painel interativo |
| GitHub | Versionamento e documentação do projeto |

## Metodologia

O desenvolvimento está organizado em etapas integradas:

### 1. Extração, transformação e carga (ETL)

- Extração dos dados disponibilizados pela API do TCE-RJ.
- Tratamento de valores ausentes e registros duplicados.
- Padronização de variáveis e conversão de tipos de dados.
- Validação da consistência das informações.
- Preparação da base tratada para armazenamento e análises posteriores.

### 2. Banco de dados

Implementação de uma estrutura relacional em PostgreSQL, utilizando Supabase como plataforma de hospedagem.

A modelagem busca organizar as informações em estruturas dimensionais, facilitando consultas, cruzamentos e análises por diferentes perspectivas, como:

- Fornecedores;
- Unidades contratantes;
- Processos;
- Itens;
- Afastamentos e demais informações relacionadas às contratações.

### 3. Análise exploratória de dados (EDA)

Investigação das características da base de dados, considerando:

- Distribuição dos valores das compras;
- Evolução temporal das contratações;
- Concentração de gastos por órgão e fornecedor;
- Distribuição dos itens e objetos contratados;
- Comportamento das variáveis e identificação de possíveis inconsistências.

### 4. Aprendizado de máquina (Machine Learning)

Aplicação de técnicas de aprendizado não supervisionado para identificação de padrões e registros com características atípicas.

**Algoritmos e técnicas utilizados:**

- **K-Means:** agrupamento de registros com características semelhantes, permitindo identificar diferentes padrões nas compras diretas.
- **Isolation Forest:** identificação de observações potencialmente anômalas a partir de seu isolamento em relação ao conjunto de dados.

Os resultados são utilizados como indicadores para direcionar análises mais detalhadas. A identificação de anomalias estatísticas não representa, isoladamente, a comprovação de irregularidades administrativas ou legais.

### 5. Business Intelligence (BI)

Desenvolvimento de um painel interativo no Power BI, integrado aos dados armazenados no banco de dados.

O painel tem como finalidade apresentar:

- Panorama geral das compras diretas;
- Evolução dos gastos ao longo do período;
- Concentração de valores por unidade contratante e fornecedor;
- Análise de processos e itens;
- Resultados das técnicas de identificação de anomalias;
- Informações para aprofundamento e fiscalização cidadã.

## Estrutura do repositório

O repositório está organizado da seguinte forma:

```text
tcc_compras_diretas/
│
├── Artigos/
│   └── Referências e materiais científicos
│
├── DB/
│   └── Estruturas e arquivos relacionados ao banco de dados
│
├── Dados/
│   └── Arquivos e bases de dados do projeto
│
├── Painel/
│   └── Arquivos do projeto Power BI
│
├── TCCr/
│   └── Documentação acadêmica
│
├── ETL_TCC_compras_diretas.ipynb
│
├── SQL_TCC_compras_diretas.ipynb
│
├── ML_TCC_compras_diretas.ipynb
│
└── README.md
```

## Organização dos notebooks

| Notebook | Descrição |
|---|---|
| `ETL_TCC_compras_diretas.ipynb` | Extração, transformação, limpeza e validação dos dados. |
| `SQL_TCC_compras_diretas.ipynb` | Operações de banco de dados, estruturação e integração das informações. |
| `ML_TCC_compras_diretas.ipynb` | Preparação das variáveis, aplicação dos algoritmos e análise dos resultados de Machine Learning. |

## Resultados esperados

O projeto busca desenvolver um ambiente analítico integrado, capaz de transformar dados públicos em informações estruturadas e acessíveis.

A integração entre banco de dados, técnicas de aprendizado de máquina e visualização de dados permite explorar padrões de contratação, identificar concentrações relevantes e sinalizar comportamentos que mereçam investigação adicional.

A proposta não substitui os mecanismos institucionais de auditoria e fiscalização, mas oferece recursos analíticos complementares para ampliar as possibilidades de acompanhamento dos gastos públicos pela sociedade.

## Finalidade acadêmica e social

Este trabalho é desenvolvido no âmbito do curso de graduação em Ciência de Dados da Universidade Católica de Petrópolis (UCP), integrando conhecimentos de programação, engenharia e análise de dados, bancos de dados, aprendizado de máquina e Business Intelligence.

Além de seu caráter acadêmico, a iniciativa busca contribuir para a transparência das compras públicas e o fortalecimento do controle social por meio do uso de tecnologias de análise de dados.

## Autor

**Marcelo Nicolay Santos**

Graduação em Ciência de Dados – Universidade Católica de Petrópolis (UCP).

## Licença

Projeto desenvolvido para fins acadêmicos e de pesquisa, utilizando dados públicos disponibilizados pelo Tribunal de Contas do Estado do Rio de Janeiro (TCE-RJ).