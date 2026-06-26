# Plan Gestor App — Controle Gerencial de Planejamento Físico

Aplicação web corporativa em HTML, CSS e JavaScript para gestão gerencial do planejamento físico de obras, com identidade visual Cury, visão SaaS, dashboards, filtros, agenda, eventos críticos, avanço físico, alertas e guia de uso.

## Estrutura do projeto

```text
Plan_gestor_app/
├── index.html
├── controle_planejamento_fisico_saas_cury.html
├── assets/
│   ├── img/
│   │   ├── logo-small.png
│   │   └── logo_texto_branco.png
│   └── screenshots/
├── backend/
│   └── api_controle_planejamento_fisico_cury.py
├── database/
│   └── banco_dados_controle_planejamento_fisico_cury.sql
├── docs/
│   └── guia_completo_plataforma_cury_planejamento_fisico.md
├── scripts/
│   ├── serve-local.ps1
│   └── serve-local.sh
├── .github/
│   └── workflows/
│       └── pages.yml
├── .gitignore
├── .gitattributes
├── package.json
└── README.md
```

## Como abrir localmente

Basta abrir o arquivo `index.html` no navegador.

Para servir por HTTP local:

```bash
python -m http.server 4173
```

Depois acesse:

```text
http://localhost:4173
```

## Publicar no GitHub

Use os comandos abaixo dentro da pasta do projeto:

```bash
git init
git remote add origin https://github.com/ERBF26/Plan_gestor_app.git
git add .
git commit -m "Publica versão inicial do Plan Gestor App"
git branch -M main
git push -u origin main
```

Caso o repositório já exista localmente:

```bash
git clone https://github.com/ERBF26/Plan_gestor_app.git
cd Plan_gestor_app
# copie os arquivos deste pacote para dentro da pasta clonada
git add .
git commit -m "Atualiza aplicação SaaS de planejamento físico"
git push
```

## GitHub Pages

Este pacote já contém o workflow `.github/workflows/pages.yml` para publicar o `index.html` no GitHub Pages.

Após enviar para o GitHub:

1. Acesse o repositório no GitHub.
2. Vá em **Settings > Pages**.
3. Em **Build and deployment**, selecione **GitHub Actions**.
4. Aguarde a action concluir.

## Funcionalidades principais

- Tela inicial corporativa.
- Clique no logo da Cury para voltar à tela inicial.
- Tema claro e escuro.
- Filtros com seletor de data.
- Dashboards responsivos.
- Tabelas com ajuste automático e rolagem horizontal.
- Exportação CSV/Excel.
- Exportação PDF via impressão.
- Compartilhamento de visão.
- Agenda de obra em Calendário, Gantt e Kanban.
- Detalhes do projeto.
- Eventos críticos.
- Avanço físico.
- Alertas.
- Usuários, perfis e permissões dentro da engrenagem de configurações.
- Central de Ajuda com metodologia, regras, FAQ e exemplos.

## Observação

A aplicação funciona de forma estática no navegador. A pasta `backend/` e `database/` foi incluída como referência para evolução futura com API e banco de dados real.
