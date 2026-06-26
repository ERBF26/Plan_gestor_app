-- =============================================================
-- BANCO DE DADOS | Controle Gerencial de Planejamento Físico
-- Modelo relacional para controle de obras, departamentos, fases,
-- datas críticas, avanço físico, alertas e histórico gerencial.
-- Compatível com SQLite. Pode ser adaptado para SQL Server/Dataverse.
-- =============================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS alerta;
DROP TABLE IF EXISTS avanco_fisico;
DROP TABLE IF EXISTS evento_critico;
DROP TABLE IF EXISTS obra;
DROP TABLE IF EXISTS fase;
DROP TABLE IF EXISTS departamento;
DROP TABLE IF EXISTS regional;
DROP TABLE IF EXISTS usuario;

CREATE TABLE regional (
    id_regional       INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_regional     TEXT NOT NULL UNIQUE,
    cidade            TEXT,
    uf                TEXT,
    ativo             INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE departamento (
    id_departamento   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_departamento TEXT NOT NULL UNIQUE,
    area_responsavel  TEXT,
    ativo             INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE fase (
    id_fase           INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_fase         TEXT NOT NULL UNIQUE,
    ordem_fase        INTEGER NOT NULL,
    tipo_fase         TEXT CHECK(tipo_fase IN ('Pré-obra','Execução','Entrega','Pós-obra')) NOT NULL,
    ativo             INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE usuario (
    id_usuario        INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_usuario      TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,
    perfil            TEXT CHECK(perfil IN ('Administrador','Gerencial','Planejamento','Engenharia','Consulta')) NOT NULL,
    ativo             INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE obra (
    id_obra                   INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_obra               TEXT NOT NULL UNIQUE,
    nome_obra                 TEXT NOT NULL,
    id_regional               INTEGER NOT NULL,
    id_departamento           INTEGER NOT NULL,
    id_fase                   INTEGER NOT NULL,
    status_obra               TEXT CHECK(status_obra IN ('Não iniciado','Em andamento','Dentro do prazo','Atenção','Crítico','Concluído')) NOT NULL,
    responsavel               TEXT NOT NULL,
    quantidade_unidades       INTEGER NOT NULL DEFAULT 0,
    percentual_avanco_fisico  REAL NOT NULL DEFAULT 0,
    data_cliente              DATE,
    data_caixa                DATE,
    data_obra                 DATE,
    data_inicio_planejada     DATE,
    data_termino_planejada    DATE,
    data_inicio_real          DATE,
    data_termino_real         DATE,
    link_cronograma           TEXT,
    observacoes               TEXT,
    ultima_atualizacao        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ativo                     INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (id_regional) REFERENCES regional(id_regional),
    FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento),
    FOREIGN KEY (id_fase) REFERENCES fase(id_fase)
);

CREATE TABLE evento_critico (
    id_evento           INTEGER PRIMARY KEY AUTOINCREMENT,
    id_obra             INTEGER NOT NULL,
    tipo_evento         TEXT CHECK(tipo_evento IN ('Cliente','Caixa','Obra')) NOT NULL,
    nome_evento         TEXT NOT NULL,
    data_evento         DATE NOT NULL,
    status_evento       TEXT CHECK(status_evento IN ('Previsto','Em andamento','Vencido','Concluído')) NOT NULL DEFAULT 'Previsto',
    prioridade          TEXT CHECK(prioridade IN ('Baixa','Média','Alta','Crítica')) NOT NULL DEFAULT 'Média',
    responsavel         TEXT,
    observacao          TEXT,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_obra) REFERENCES obra(id_obra)
);

CREATE TABLE avanco_fisico (
    id_avanco              INTEGER PRIMARY KEY AUTOINCREMENT,
    id_obra                INTEGER NOT NULL,
    data_referencia        DATE NOT NULL,
    mes_ano                TEXT NOT NULL,
    previsto_mensal        REAL NOT NULL DEFAULT 0,
    realizado_mensal       REAL NOT NULL DEFAULT 0,
    previsto_acumulado     REAL NOT NULL DEFAULT 0,
    realizado_acumulado    REAL NOT NULL DEFAULT 0,
    desvio_acumulado       REAL GENERATED ALWAYS AS (realizado_acumulado - previsto_acumulado) VIRTUAL,
    spi_fisico             REAL GENERATED ALWAYS AS (
        CASE WHEN previsto_acumulado = 0 THEN NULL ELSE realizado_acumulado / previsto_acumulado END
    ) VIRTUAL,
    unidade_produzida      REAL NOT NULL DEFAULT 0,
    atualizado_em          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_obra) REFERENCES obra(id_obra)
);

CREATE TABLE alerta (
    id_alerta           INTEGER PRIMARY KEY AUTOINCREMENT,
    id_obra             INTEGER NOT NULL,
    tipo_alerta         TEXT NOT NULL,
    nivel_alerta        TEXT CHECK(nivel_alerta IN ('Normal','Atenção','Crítico','Concluído')) NOT NULL DEFAULT 'Normal',
    descricao           TEXT NOT NULL,
    data_limite         DATE,
    responsavel         TEXT,
    acao_recomendada    TEXT,
    status_alerta       TEXT CHECK(status_alerta IN ('Aberto','Em tratativa','Resolvido')) NOT NULL DEFAULT 'Aberto',
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolvido_em        DATETIME,
    FOREIGN KEY (id_obra) REFERENCES obra(id_obra)
);

CREATE INDEX idx_obra_departamento ON obra(id_departamento);
CREATE INDEX idx_obra_fase ON obra(id_fase);
CREATE INDEX idx_obra_status ON obra(status_obra);
CREATE INDEX idx_evento_data ON evento_critico(data_evento);
CREATE INDEX idx_avanco_data ON avanco_fisico(data_referencia);
CREATE INDEX idx_alerta_nivel ON alerta(nivel_alerta);

-- =============================================================
-- CARGA INICIAL / SEED
-- =============================================================

INSERT INTO regional (nome_regional, cidade, uf) VALUES
('São Paulo', 'São Paulo', 'SP'),
('Rio de Janeiro', 'Rio de Janeiro', 'RJ'),
('ABC Paulista', 'Santo André', 'SP'),
('Baixada Santista', 'Santos', 'SP');

INSERT INTO departamento (nome_departamento, area_responsavel) VALUES
('Planejamento', 'Planejamento Físico'),
('Engenharia', 'Obras'),
('Projetos', 'Projetos Executivos'),
('Suprimentos', 'Contratações'),
('Legalização', 'Aprovações'),
('Qualidade', 'Controle de Qualidade'),
('Incorporação', 'Desenvolvimento Imobiliário');

INSERT INTO fase (nome_fase, ordem_fase, tipo_fase) VALUES
('Prospecção / Estudo', 1, 'Pré-obra'),
('Pré-obra', 2, 'Pré-obra'),
('Aprovação / Licenças', 3, 'Pré-obra'),
('Mobilização', 4, 'Execução'),
('Fundação', 5, 'Execução'),
('Estrutura', 6, 'Execução'),
('Acabamento', 7, 'Execução'),
('Vistoria', 8, 'Entrega'),
('Entrega', 9, 'Entrega'),
('Pós-obra', 10, 'Pós-obra');

INSERT INTO usuario (nome_usuario, email, perfil) VALUES
('Admin Planejamento', 'admin.planejamento@cury.com.br', 'Administrador'),
('Gestor Engenharia', 'gestor.engenharia@cury.com.br', 'Gerencial'),
('Planejador Físico', 'planejador.fisico@cury.com.br', 'Planejamento');

INSERT INTO obra (
    codigo_obra, nome_obra, id_regional, id_departamento, id_fase, status_obra, responsavel,
    quantidade_unidades, percentual_avanco_fisico, data_cliente, data_caixa, data_obra,
    data_inicio_planejada, data_termino_planejada, link_cronograma, observacoes
) VALUES
('OBR-001', 'Reserva Alto do Sol', 1, 1, 6, 'Em andamento', 'Mariana Alves', 420, 62.5, '2026-07-05', '2026-07-12', '2026-07-18', '2025-11-01', '2027-04-30', 'https://cronograma/obr-001', 'Estrutura em evolução com atenção à produtividade.'),
('OBR-002', 'Vista Parque RJ', 2, 2, 5, 'Dentro do prazo', 'Carlos Souza', 360, 44.0, '2026-07-20', '2026-07-25', '2026-08-01', '2026-01-10', '2027-08-20', 'https://cronograma/obr-002', 'Fundação dentro do planejado.'),
('OBR-003', 'Jardins Cury SP', 1, 5, 2, 'Atenção', 'Renata Lima', 280, 12.0, '2026-06-30', '2026-07-08', '2026-07-14', '2026-05-01', '2027-11-15', 'https://cronograma/obr-003', 'Pendência de documentação na pré-obra.'),
('OBR-004', 'Atlântico Residencial', 4, 3, 3, 'Crítico', 'Felipe Martins', 520, 8.5, '2026-06-27', '2026-06-29', '2026-07-10', '2026-04-15', '2028-01-31', 'https://cronograma/obr-004', 'Licenças com risco de impacto no início físico.'),
('OBR-005', 'Conquista ABC', 3, 1, 7, 'Em andamento', 'Juliana Rocha', 310, 71.2, '2026-08-10', '2026-08-15', '2026-08-25', '2025-09-01', '2027-02-28', 'https://cronograma/obr-005', 'Acabamento em evolução.'),
('OBR-006', 'Nova Estação', 1, 4, 4, 'Atenção', 'Bruno Torres', 260, 24.3, '2026-07-02', '2026-07-05', '2026-07-09', '2026-03-01', '2027-10-30', 'https://cronograma/obr-006', 'Mobilização com pendências de suprimentos.'),
('OBR-007', 'Horizonte Verde', 2, 6, 8, 'Dentro do prazo', 'Camila Nunes', 190, 88.4, '2026-09-01', '2026-09-06', '2026-09-12', '2025-04-01', '2026-12-15', 'https://cronograma/obr-007', 'Vistoria dentro do ciclo previsto.'),
('OBR-008', 'Cury Central', 1, 7, 1, 'Não iniciado', 'André Melo', 610, 0.0, '2026-10-15', '2026-10-25', '2026-11-01', '2026-09-01', '2028-05-30', 'https://cronograma/obr-008', 'Empreendimento em estudo inicial.');

INSERT INTO evento_critico (id_obra, tipo_evento, nome_evento, data_evento, status_evento, prioridade, responsavel, observacao) VALUES
(1, 'Cliente', 'Reunião de validação do marco estrutural', '2026-07-05', 'Previsto', 'Alta', 'Mariana Alves', 'Apresentar status de estrutura.'),
(1, 'Caixa', 'Medição Caixa - Estrutura', '2026-07-12', 'Previsto', 'Média', 'Mariana Alves', 'Preparar documentação de medição.'),
(3, 'Cliente', 'Entrega de pendências de pré-obra', '2026-06-30', 'Previsto', 'Alta', 'Renata Lima', 'Prazo crítico para avanço da fase.'),
(4, 'Caixa', 'Validação documental Caixa', '2026-06-29', 'Previsto', 'Crítica', 'Felipe Martins', 'Risco de impacto em mobilização.'),
(6, 'Obra', 'Início da mobilização de campo', '2026-07-09', 'Previsto', 'Alta', 'Bruno Torres', 'Acompanhar suprimentos.'),
(7, 'Obra', 'Vistoria interna', '2026-09-12', 'Previsto', 'Média', 'Camila Nunes', 'Checar pendências de qualidade.');

INSERT INTO avanco_fisico (id_obra, data_referencia, mes_ano, previsto_mensal, realizado_mensal, previsto_acumulado, realizado_acumulado, unidade_produzida) VALUES
(1, '2026-01-31', 'Jan/2026', 8.0, 7.2, 28.0, 26.4, 30),
(1, '2026-02-28', 'Fev/2026', 7.5, 8.1, 35.5, 34.5, 34),
(1, '2026-03-31', 'Mar/2026', 8.5, 7.9, 44.0, 42.4, 33),
(1, '2026-04-30', 'Abr/2026', 7.0, 7.4, 51.0, 49.8, 31),
(1, '2026-05-31', 'Mai/2026', 6.5, 6.8, 57.5, 56.6, 28),
(1, '2026-06-30', 'Jun/2026', 6.8, 5.9, 64.3, 62.5, 25),
(2, '2026-01-31', 'Jan/2026', 5.0, 4.8, 5.0, 4.8, 15),
(2, '2026-02-28', 'Fev/2026', 6.2, 6.4, 11.2, 11.2, 22),
(2, '2026-03-31', 'Mar/2026', 7.1, 7.4, 18.3, 18.6, 25),
(2, '2026-04-30', 'Abr/2026', 8.0, 7.9, 26.3, 26.5, 29),
(2, '2026-05-31', 'Mai/2026', 8.5, 8.7, 34.8, 35.2, 32),
(2, '2026-06-30', 'Jun/2026', 9.0, 8.8, 43.8, 44.0, 34),
(5, '2026-01-31', 'Jan/2026', 10.0, 9.8, 39.0, 38.5, 35),
(5, '2026-02-28', 'Fev/2026', 9.0, 9.4, 48.0, 47.9, 34),
(5, '2026-03-31', 'Mar/2026', 8.5, 8.7, 56.5, 56.6, 31),
(5, '2026-04-30', 'Abr/2026', 7.5, 7.8, 64.0, 64.4, 29),
(5, '2026-05-31', 'Mai/2026', 6.8, 6.5, 70.8, 70.9, 24),
(5, '2026-06-30', 'Jun/2026', 5.0, 0.3, 75.8, 71.2, 2);

INSERT INTO alerta (id_obra, tipo_alerta, nivel_alerta, descricao, data_limite, responsavel, acao_recomendada, status_alerta) VALUES
(4, 'Data da Caixa vencendo', 'Crítico', 'Validação documental da Caixa está próxima e impacta o início da obra.', '2026-06-29', 'Felipe Martins', 'Priorizar documentação e acionar Legalização.', 'Aberto'),
(3, 'Pré-obra parada', 'Atenção', 'Obra permanece em pré-obra com pendências documentais.', '2026-06-30', 'Renata Lima', 'Revisar pendências e atualizar plano de ação.', 'Em tratativa'),
(6, 'Suprimentos pendente', 'Atenção', 'Mobilização depende de contratos e materiais críticos.', '2026-07-05', 'Bruno Torres', 'Reforçar status com Suprimentos.', 'Aberto'),
(1, 'Desvio físico acumulado', 'Atenção', 'Realizado acumulado abaixo do previsto no último mês.', '2026-07-01', 'Mariana Alves', 'Criar plano de recuperação semanal.', 'Aberto'),
(7, 'Vistoria próxima', 'Normal', 'Vistoria interna planejada dentro do prazo.', '2026-09-12', 'Camila Nunes', 'Manter checklist de qualidade atualizado.', 'Aberto');
