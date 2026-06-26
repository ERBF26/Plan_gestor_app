"""
API FastAPI | Controle Gerencial de Planejamento Físico
--------------------------------------------------------
Executar:
    pip install fastapi uvicorn
    uvicorn backend.main:app --reload --port 8000

Endpoints principais:
    GET /api/dashboard
    GET /api/obras
    GET /api/departamentos
    GET /api/fases
    GET /api/eventos
    GET /api/alertas
    GET /api/avanco
"""
from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

BASE_DIR = Path(__file__).resolve().parents[1]
DB_PATH = BASE_DIR / "database" / "controle_planejamento_fisico.db"
SCHEMA_PATH = BASE_DIR / "database" / "schema_seed.sql"

app = FastAPI(
    title="Controle Gerencial de Planejamento Físico",
    description="API para dashboard executivo de obras, fases, departamentos, datas críticas e avanço físico.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def rows_to_dict(rows: List[sqlite3.Row]) -> List[Dict[str, Any]]:
    return [dict(row) for row in rows]


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not DB_PATH.exists():
        with get_conn() as conn:
            conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
            conn.commit()


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.get("/api/dashboard")
def dashboard() -> Dict[str, Any]:
    with get_conn() as conn:
        total_obras = conn.execute("SELECT COUNT(*) FROM obra WHERE ativo = 1").fetchone()[0]
        pre_obra = conn.execute(
            """
            SELECT COUNT(*)
            FROM obra o
            JOIN fase f ON f.id_fase = o.id_fase
            WHERE o.ativo = 1 AND f.tipo_fase = 'Pré-obra'
            """
        ).fetchone()[0]
        execucao = conn.execute(
            """
            SELECT COUNT(*)
            FROM obra o
            JOIN fase f ON f.id_fase = o.id_fase
            WHERE o.ativo = 1 AND f.tipo_fase = 'Execução'
            """
        ).fetchone()[0]
        atrasadas = conn.execute(
            "SELECT COUNT(*) FROM obra WHERE ativo = 1 AND status_obra IN ('Atenção','Crítico')"
        ).fetchone()[0]
        dentro_prazo = conn.execute(
            "SELECT COUNT(*) FROM obra WHERE ativo = 1 AND status_obra = 'Dentro do prazo'"
        ).fetchone()[0]
        datas_criticas = conn.execute(
            """
            SELECT COUNT(*)
            FROM evento_critico
            WHERE date(data_evento) BETWEEN date('now') AND date('now', '+45 days')
              AND status_evento <> 'Concluído'
            """
        ).fetchone()[0]
        media_avanco = conn.execute(
            "SELECT COALESCE(ROUND(AVG(percentual_avanco_fisico), 1), 0) FROM obra WHERE ativo = 1"
        ).fetchone()[0]
        unidades = conn.execute(
            "SELECT COALESCE(SUM(quantidade_unidades), 0) FROM obra WHERE ativo = 1"
        ).fetchone()[0]

        status = rows_to_dict(conn.execute(
            "SELECT status_obra AS status, COUNT(*) AS quantidade FROM obra WHERE ativo = 1 GROUP BY status_obra"
        ).fetchall())

        return {
            "total_obras": total_obras,
            "pre_obra": pre_obra,
            "execucao": execucao,
            "obras_atencao_critico": atrasadas,
            "dentro_prazo": dentro_prazo,
            "datas_criticas_45d": datas_criticas,
            "media_avanco_fisico": media_avanco,
            "quantidade_unidades": unidades,
            "status": status,
        }


@app.get("/api/obras")
def obras(
    departamento: Optional[str] = Query(None),
    fase: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    regional: Optional[str] = Query(None),
) -> List[Dict[str, Any]]:
    sql = """
        SELECT
            o.id_obra,
            o.codigo_obra,
            o.nome_obra,
            r.nome_regional,
            d.nome_departamento,
            f.nome_fase,
            f.tipo_fase,
            o.status_obra,
            o.responsavel,
            o.quantidade_unidades,
            o.percentual_avanco_fisico,
            o.data_cliente,
            o.data_caixa,
            o.data_obra,
            o.data_inicio_planejada,
            o.data_termino_planejada,
            o.link_cronograma,
            o.observacoes,
            o.ultima_atualizacao
        FROM obra o
        JOIN regional r ON r.id_regional = o.id_regional
        JOIN departamento d ON d.id_departamento = o.id_departamento
        JOIN fase f ON f.id_fase = o.id_fase
        WHERE o.ativo = 1
    """
    params: List[Any] = []
    if departamento:
        sql += " AND d.nome_departamento = ?"
        params.append(departamento)
    if fase:
        sql += " AND f.nome_fase = ?"
        params.append(fase)
    if status:
        sql += " AND o.status_obra = ?"
        params.append(status)
    if regional:
        sql += " AND r.nome_regional = ?"
        params.append(regional)
    sql += " ORDER BY o.ultima_atualizacao DESC"

    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql, params).fetchall())


@app.get("/api/departamentos")
def departamentos() -> List[Dict[str, Any]]:
    sql = """
        SELECT
            d.nome_departamento,
            COUNT(o.id_obra) AS quantidade_obras,
            COALESCE(ROUND(AVG(o.percentual_avanco_fisico), 1), 0) AS avanco_medio,
            SUM(CASE WHEN o.status_obra = 'Crítico' THEN 1 ELSE 0 END) AS obras_criticas,
            SUM(CASE WHEN o.status_obra = 'Atenção' THEN 1 ELSE 0 END) AS obras_atencao,
            SUM(CASE WHEN f.tipo_fase = 'Pré-obra' THEN 1 ELSE 0 END) AS pre_obra,
            SUM(CASE WHEN f.tipo_fase = 'Execução' THEN 1 ELSE 0 END) AS execucao
        FROM departamento d
        LEFT JOIN obra o ON o.id_departamento = d.id_departamento AND o.ativo = 1
        LEFT JOIN fase f ON f.id_fase = o.id_fase
        WHERE d.ativo = 1
        GROUP BY d.nome_departamento
        ORDER BY quantidade_obras DESC, d.nome_departamento
    """
    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql).fetchall())


@app.get("/api/fases")
def fases() -> List[Dict[str, Any]]:
    sql = """
        SELECT
            f.nome_fase,
            f.tipo_fase,
            f.ordem_fase,
            COUNT(o.id_obra) AS quantidade_obras,
            COALESCE(ROUND(AVG(o.percentual_avanco_fisico), 1), 0) AS avanco_medio,
            SUM(CASE WHEN o.status_obra IN ('Atenção','Crítico') THEN 1 ELSE 0 END) AS obras_com_risco
        FROM fase f
        LEFT JOIN obra o ON o.id_fase = f.id_fase AND o.ativo = 1
        WHERE f.ativo = 1
        GROUP BY f.nome_fase, f.tipo_fase, f.ordem_fase
        ORDER BY f.ordem_fase
    """
    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql).fetchall())


@app.get("/api/eventos")
def eventos(tipo: Optional[str] = Query(None)) -> List[Dict[str, Any]]:
    sql = """
        SELECT
            e.id_evento,
            o.codigo_obra,
            o.nome_obra,
            e.tipo_evento,
            e.nome_evento,
            e.data_evento,
            e.status_evento,
            e.prioridade,
            e.responsavel,
            e.observacao
        FROM evento_critico e
        JOIN obra o ON o.id_obra = e.id_obra
        WHERE 1 = 1
    """
    params: List[Any] = []
    if tipo:
        sql += " AND e.tipo_evento = ?"
        params.append(tipo)
    sql += " ORDER BY date(e.data_evento) ASC"

    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql, params).fetchall())


@app.get("/api/alertas")
def alertas(nivel: Optional[str] = Query(None)) -> List[Dict[str, Any]]:
    sql = """
        SELECT
            a.id_alerta,
            o.codigo_obra,
            o.nome_obra,
            a.tipo_alerta,
            a.nivel_alerta,
            a.descricao,
            a.data_limite,
            a.responsavel,
            a.acao_recomendada,
            a.status_alerta,
            a.criado_em
        FROM alerta a
        JOIN obra o ON o.id_obra = a.id_obra
        WHERE 1 = 1
    """
    params: List[Any] = []
    if nivel:
        sql += " AND a.nivel_alerta = ?"
        params.append(nivel)
    sql += " ORDER BY CASE a.nivel_alerta WHEN 'Crítico' THEN 1 WHEN 'Atenção' THEN 2 WHEN 'Normal' THEN 3 ELSE 4 END, date(a.data_limite) ASC"

    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql, params).fetchall())


@app.get("/api/avanco")
def avanco(id_obra: Optional[int] = Query(None)) -> List[Dict[str, Any]]:
    sql = """
        SELECT
            a.id_obra,
            o.codigo_obra,
            o.nome_obra,
            a.data_referencia,
            a.mes_ano,
            a.previsto_mensal,
            a.realizado_mensal,
            a.previsto_acumulado,
            a.realizado_acumulado,
            ROUND(a.realizado_acumulado - a.previsto_acumulado, 2) AS desvio_acumulado,
            CASE WHEN a.previsto_acumulado = 0 THEN NULL ELSE ROUND(a.realizado_acumulado / a.previsto_acumulado, 3) END AS spi_fisico,
            a.unidade_produzida
        FROM avanco_fisico a
        JOIN obra o ON o.id_obra = a.id_obra
        WHERE 1 = 1
    """
    params: List[Any] = []
    if id_obra:
        sql += " AND a.id_obra = ?"
        params.append(id_obra)
    sql += " ORDER BY a.data_referencia ASC"

    with get_conn() as conn:
        return rows_to_dict(conn.execute(sql, params).fetchall())
