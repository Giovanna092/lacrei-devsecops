# Documentação Técnica — Lacrei DevSecOps

## 1. Objetivo

Este documento descreve a implementação realizada no desafio DevSecOps, desde a preparação da aplicação até a execução do deploy automatizado em AWS Lightsail.

O objetivo da solução é estabelecer um fluxo simples e funcional de integração, segurança e entrega contínua:

```text
Código → Testes → Docker → Segurança → Docker Hub → AWS
```

---

## 2. Estrutura geral da solução

A solução utiliza dois workflows do GitHub Actions:

- `ci.yml`: integração contínua e análise de segurança.
- `cd.yml`: publicação da imagem e deploy.

O fluxo começa com um push na branch `main`.

```text
GitHub
  |
  v
CI
  |
  +--> Testes Jest
  |
  +--> Docker Build
  |
  +--> OWASP ZAP
  |
  v
CI aprovado
  |
  v
CD
  |
  +--> Build da imagem
  |
  +--> Push Docker Hub
  |
  +--> SSH para AWS Lightsail
          |
          +--> docker pull
          +--> stop/remove container anterior
          +--> docker run
```

---

## 3. Aplicação Node.js

A aplicação foi preparada e validada localmente antes da criação da pipeline.

### Instalação

Foi executado:

```bash
npm install
```

A instalação foi concluída com sucesso e a auditoria do npm indicou:

```text
found 0 vulnerabilities
```

O npm apresentou alguns avisos de dependências e scripts de instalação, mas isso não impediu a execução da aplicação.

### Testes

O comando:

```bash
npm test
```

executou o Jest com sucesso:

```text
Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

O teste existente valida o endpoint:

```text
GET /status
```

### Execução

A aplicação é iniciada com:

```bash
npm start
```

O servidor utiliza a porta `3000`.

A validação local retornou:

```json
{"status":"ok"}
```

---

## 4. Dockerização

Foi criado um `Dockerfile` para empacotar a aplicação em uma imagem Docker.

Também foi criado um `.dockerignore` para evitar o envio de arquivos desnecessários para o contexto do build.

A imagem utilizada no projeto é:

```text
giovanna092/lacrei-devsecops:latest
```

A imagem foi validada localmente com `docker build` e `docker run`.

Um teste adicional demonstrou o comportamento esperado das imagens Docker: alterações feitas no código local não alteram automaticamente uma imagem que já foi construída. Para refletir uma alteração na imagem, é necessário executar um novo build.

---

## 5. GitHub Actions — CI

O workflow de CI é responsável pelas verificações antes da publicação.

As etapas implementadas incluem:

1. Checkout do código.
2. Instalação das dependências.
3. Execução dos testes.
4. Build da imagem Docker.
5. Execução do OWASP ZAP.

O build Docker foi executado como uma etapa independente da pipeline e apresentou resultado de sucesso.

---

## 6. OWASP ZAP

Foi utilizada a imagem:

```text
ghcr.io/zaproxy/zaproxy:stable
```

O ZAP executa uma análise dinâmica contra a aplicação em execução na pipeline.

O alvo utilizado foi:

```text
http://localhost:3000
```

O relatório HTML do ZAP foi gerado como artefato da execução do GitHub Actions.

### Resultado observado

No relatório final analisado:

- High: 0
- Medium: 1
- Low: 2
- Informational: 1
- False Positives: 0

O ZAP também identificou avisos relacionados, entre outros, a:

- `X-Powered-By`
- conteúdo armazenável/cacheável
- CSP
- Permissions Policy

Esses resultados foram mantidos como achados da análise, sem mascarar ou afirmar que a aplicação não possui nenhum alerta.

Também houve uma ocorrência de `404` durante a tentativa de spider em URLs como `/robots.txt` e `/sitemap.xml`. Isso não impediu a execução do scan utilizado no pipeline.

---

## 7. Docker Hub

Foi criado o repositório:

```text
giovanna092/lacrei-devsecops
```

O CD realiza login utilizando GitHub Secrets e publica a imagem:

```text
giovanna092/lacrei-devsecops:latest
```

O uso de `latest` foi adotado para manter a implementação simples para o escopo do desafio.

---

## 8. GitHub Secrets

As credenciais utilizadas pela pipeline não são armazenadas diretamente no código.

Foram configurados os seguintes secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
AWS_HOST
AWS_SSH_KEY
```

### Docker Hub

`DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN` são utilizados para autenticar o workflow no Docker Hub.

### AWS

`AWS_HOST` contém o endereço público da instância.

`AWS_SSH_KEY` contém a chave privada utilizada para autenticação SSH.

A chave privada não deve ser commitada ou publicada no repositório.

---

## 9. AWS Lightsail

Foi criada uma instância AWS Lightsail utilizando Ubuntu.

O Docker Engine foi instalado e validado com:

```bash
sudo docker --version
```

A instalação foi testada executando:

```bash
sudo docker run hello-world
```

O teste confirmou que o Docker conseguia:

1. comunicar-se com o daemon;
2. baixar uma imagem do Docker Hub;
3. criar um container;
4. executar o container.

---

## 10. Deploy manual inicial

Antes da automação do deploy, a imagem foi baixada manualmente na instância:

```bash
sudo docker pull giovanna092/lacrei-devsecops:latest
```

Em seguida, a aplicação foi executada:

```bash
sudo docker run -d   --name lacrei-app   -p 3000:3000   giovanna092/lacrei-devsecops:latest
```

A execução foi validada com:

```bash
sudo docker ps
```

E:

```bash
curl http://localhost:3000/status
```

Resultado:

```json
{"status":"ok"}
```

---

## 11. Firewall AWS

Foi adicionada uma regra de entrada para:

```text
TCP 3000
```

A porta é utilizada pelo container da aplicação.

A configuração permitiu validar o endpoint utilizando o endereço público da instância:

```text
http://IP_PUBLICO:3000/status
```

O acesso externo retornou:

```json
{"status":"ok"}
```

---

## 12. Deploy automatizado

O workflow `cd.yml` é disparado após o workflow `CI` terminar com sucesso na branch `main`.

A etapa de deploy utiliza SSH para acessar a instância:

```yaml
uses: appleboy/ssh-action@v1.2.2
```

Dentro da instância, os comandos executados são equivalentes a:

```bash
sudo docker pull giovanna092/lacrei-devsecops:latest
sudo docker stop lacrei-app || true
sudo docker rm lacrei-app || true
sudo docker run -d   --name lacrei-app   -p 3000:3000   giovanna092/lacrei-devsecops:latest
```

Os `|| true` permitem que o primeiro deploy seja executado mesmo quando ainda não existe um container chamado `lacrei-app`.

---

## 13. Validação final do CD

Após o push para a branch `main`, foi observado o seguinte fluxo:

```text
CI → sucesso
     ↓
CD → sucesso
     ↓
Docker Hub → imagem publicada
     ↓
AWS → container atualizado
```

Na AWS, o container foi identificado como:

```text
lacrei-app
```

utilizando:

```text
giovanna092/lacrei-devsecops:latest
```

O endpoint local na instância retornou:

```json
{"status":"ok"}
```

O mesmo endpoint também foi acessado pelo IP público da instância a partir da máquina local, retornando:

```json
{"status":"ok"}
```

Isso confirmou o funcionamento do fluxo completo de entrega.

---

## 14. Resultado

A implementação final possui um pipeline funcional de CI/CD com:

- testes automatizados;
- build Docker;
- análise dinâmica com OWASP ZAP;
- publicação da imagem no Docker Hub;
- autenticação por GitHub Secrets;
- deploy automatizado via SSH;
- execução da aplicação em container na AWS Lightsail;
- validação interna e externa do endpoint.

### Fluxo final

```text
              ┌───────────────┐
              │    GitHub     │
              │     main      │
              └───────┬───────┘
                      │
                      v
              ┌───────────────┐
              │      CI       │
              ├───────────────┤
              │ npm test      │
              │ Docker build  │
              │ OWASP ZAP     │
              └───────┬───────┘
                      │
                   sucesso
                      │
                      v
              ┌───────────────┐
              │      CD       │
              ├───────────────┤
              │ Docker build  │
              │ Docker push   │
              │ SSH → AWS     │
              └───────┬───────┘
                      │
                      v
              ┌───────────────┐
              │  Docker Hub   │
              │     :latest   │
              └───────┬───────┘
                      │
                      v
              ┌───────────────┐
              │ AWS Lightsail │
              ├───────────────┤
              │ docker pull   │
              │ container     │
              │ Node.js       │
              └───────┬───────┘
                      │
                      v
          /status → {"status":"ok"}
```

## 15. Observação sobre segurança

A solução implementa controles básicos e adequados ao escopo desenvolvido, mas não representa uma arquitetura de produção completa.

Entre os pontos que poderiam ser evoluídos em um ambiente real estão HTTPS/TLS, gerenciamento de versões imutáveis de imagens, política de firewall mais restritiva, gerenciamento de segredos mais avançado, monitoramento e hardening da instância.

Esses itens não foram adicionados para manter a implementação compatível com o escopo e o objetivo do desafio.
