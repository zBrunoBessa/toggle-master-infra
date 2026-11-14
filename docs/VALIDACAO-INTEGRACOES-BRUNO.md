# Validacao das integracoes - Bruno

Data: 14/11/2026.

- AWS Academy: conta 891376974889, us-east-1.
- New Relic: conta 8736082, chave de ingestao configurada no Terraform; telemetria real ainda pendente.
- PagerDuty: https://fiaptech.pagerduty.com, plano Free confirmado no painel.
- Servico: ToggleMaster (P4ENGGF), responsavel Bruno Bessa, escalation policy Default.
- Integracao Events API v2: PE21MQ3.
- Configuracao privada: terraform/platform/observability.auto.tfvars.json; arquivo ignorado pelo Git e permissao 600. Contem new_relic_license_key, pagerduty_routing_key e discord_webhook_url. Nunca versionar os valores.

## Teste isolado da integracao PagerDuty

Evento enviado pelo CloudShell para Events API v2. O comando leu a chave do arquivo privado, sem inseri-la no historico ou nos argumentos do processo.

- Trigger: HTTP 202, status success; incidente apareceu como Triggered e atribuido a Bruno.
- Resolve: HTTP 202, status success; estado final Resolved confirmado na interface.
- Incidente: https://fiaptech.pagerduty.com/incidents/Q2RMLBOMF4X8QA
- Titulo: [TESTE DE INTEGRACAO] ToggleMaster - Events API v2.

Este teste valida a chave e a abertura/resolucao de incidentes. Nao valida Prometheus, Alertmanager, EKS, Discord ou self-healing. A prova completa da Fase 4 continua pendente apos a implantacao.

## Pendencias

- Publicar as alteracoes nas copias pessoais e configurar secrets do CI.
- Configurar token GitOps limitado ao repositorio pessoal de infraestrutura.
- Implantacao Terraform, aplicacoes e observabilidade.
- Falha controlada com alerta real, incidente, ChatOps e recuperacao automatica.

## Discord validado

- Servidor FIAP, canal toggle-master-alertas; webhook ToggleMaster Alertas.
- Envio isolado pelo CloudShell: HTTP 200; mensagem visivel no canal.
- Evidencia: https://discord.com/channels/1571192526227111977/1571192669772849322/1571193874561376449
- Este teste valida apenas o webhook. Alertas reais dependem do deploy.

## Implantacao pessoal preparada

- Owner GitHub: zBrunoBessa.
- Repositorios: toggle-master-infra, toggle-master-ci e toggle-master-{auth,flag,targeting,evaluation,analytics}-service.
- Branch de trabalho: deploy/bruno-891376974889.
- Cinco pipelines usam secrets BRUNO_AWS_ACCESS_KEY_ID, BRUNO_AWS_SECRET_ACCESS_KEY, BRUNO_AWS_SESSION_TOKEN e BRUNO_GITOPS_TOKEN.
- CI valida a conta 891376974889 antes do push no ECR; GitOps e as 13 Applications apontam para a copia pessoal.
- actionlint 1.7.11 validou os workflows; credenciais reais e execucao do CI ainda pendentes.
- Nenhum Terraform apply executado neste checkpoint.
