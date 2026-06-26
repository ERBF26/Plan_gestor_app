# Deploy no GitHub

## Repositório alvo

`https://github.com/ERBF26/Plan_gestor_app.git`

## Enviar arquivos

```bash
git clone https://github.com/ERBF26/Plan_gestor_app.git
cd Plan_gestor_app
# copie os arquivos do pacote para esta pasta
git add .
git commit -m "Atualiza pacote estruturado do Plan Gestor App"
git push
```

## Publicar com GitHub Pages

1. Abra o repositório.
2. Entre em **Settings > Pages**.
3. Selecione **GitHub Actions**.
4. Faça push na branch `main`.
5. Aguarde a action `Deploy static site to GitHub Pages`.
