# Lacrei DevSecOps

Pipeline de CI/CD para uma aplicação Node.js, com testes automatizados, build Docker, análise de segurança com OWASP ZAP, publicação no Docker Hub e deploy automatizado em uma instância AWS Lightsail.

## Fluxo

```text
Push na main
    |
    v
  CI
  ├── npm install
  ├── Jest
  ├── Docker build
  └── OWASP ZAP
    |
    | sucesso
    v
  CD
  ├── Build da imagem
  ├── Push para Docker Hub
  └── Deploy via SSH na AWS Lightsail
          |
          v
      Docker container
          |
          v
  /status -> {"status":"ok"}
```

## Tecnologias

- Node.js / npm
- Jest
- Docker
- GitHub Actions
- OWASP ZAP
- Docker Hub
- AWS Lightsail
- Ubuntu
- SSH

## Aplicação

A aplicação possui o endpoint de verificação:

```text
GET /status
```

Resposta esperada:

```json
{"status":"ok"}
```

## CI/CD

O workflow `CI` executa os testes, constrói a imagem Docker e executa uma análise dinâmica com OWASP ZAP.

O workflow `CD` é disparado após uma execução bem-sucedida do `CI` na branch `main`. Ele publica a imagem no Docker Hub e, em seguida, conecta-se à instância AWS por SSH para atualizar o container da aplicação.

## Segurança

As credenciais não ficam armazenadas no código-fonte. O acesso ao Docker Hub e à AWS utiliza GitHub Secrets.

Secrets utilizados:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `AWS_HOST`
- `AWS_SSH_KEY`

A chave privada SSH não deve ser versionada no repositório.

## Documentação

A documentação técnica detalhada da implementação está em:

[`docs/technical_documentation.md`](docs/technical_documentation.md)
