# Roteiro de apresentação — Fase 4

Ambiente pessoal de Bruno: AWS Academy 891376974889, us-east-1, EKS toggle-master-dev-eks. Código na branch deploy/bruno-891376974889 dos repositórios de zBrunoBessa.

## Preparação

1. Iniciar o Learner Lab e conferir o tempo restante e o saldo. Abrir o console AWS pelo laboratório.
2. No CloudShell, confirmar a identidade antes de qualquer operação:

```bash
aws sts get-caller-identity --query Account --output text
aws eks update-kubeconfig --region us-east-1 --name toggle-master-dev-eks --alias fiap-bruno
kubectl get nodes
kubectl -n argocd get applications
kubectl -n toggle-master get pods
```

A conta esperada é 891376974889. Não aplicar Terraform em outra conta nem substituir o estado existente. A implantação já foi realizada; para a gravação, primeiro verificar os recursos existentes.

3. Entrar no New Relic (conta 8736082), PagerDuty fiaptech e Discord Servidor FIAP / toggle-master-alertas.
4. Abrir os painéis privados por túnel Kubernetes no computador que possui um kubeconfig autorizado. Cada comando abaixo fica em um terminal separado:

```bash
kubectl -n monitoring port-forward --address 127.0.0.1 svc/kube-prometheus-stack-grafana 3000:80
kubectl -n argocd port-forward --address 127.0.0.1 svc/argocd-server 8081:80
kubectl -n monitoring port-forward --address 127.0.0.1 svc/kube-prometheus-stack-prometheus 9090:9090
```

O localhost do CloudShell é diferente do localhost do computador. Executar esses comandos somente no CloudShell não abre os painéis no navegador local. O acesso local ainda depende da configuração autorizada do kubeconfig. Não publicar esses painéis na internet para contornar o acesso.

5. Selecionar o dashboard ToggleMaster Overview. Gerar tráfego e conferir CPU, memória, requisições, erros, latência e logs antes de começar a gravação.
6. No New Relic, abrir Distributed tracing > GET /evaluate > trace com os cinco serviços. A captura de referência é o trace 09d0db4985d7914f883cbcefcf9a59ca, de 14/11/2026 às 16:53 UTC. Ajustar o período de busca se necessário. Para outra data, gerar nova avaliação para obter evidência recente.

## Vídeo — até 25 minutos

| Minutos | Demonstração |
|---|---|
| 0–3 | Objetivo, cinco serviços e arquitetura AWS, Terraform e GitOps |
| 3–6 | Pipeline concluído: testes/verificações de segurança, imagem no ECR e atualização GitOps |
| 6–9 | EKS com nós Ready, pods saudáveis e Argo CD Synced/Healthy |
| 9–13 | Grafana: recursos do cluster, taxas de requisição/erro, latência e logs Loki |
| 13–16 | New Relic: mapa dos cinco serviços e trace de /evaluate, incluindo propagação assíncrona |
| 16–23 | Falha controlada, alerta Firing, PagerDuty, Discord, restart e recuperação HTTP 200 |
| 23–25 | Resolução, limites do laboratório, decisões técnicas e conclusão |

O intervalo do Alertmanager é de cinco minutos; preparar o trecho final considerando esse tempo. Caso grave cortes, manter a sequência e os horários visíveis para demonstrar que a recuperação foi real.

## Teste de falha reproduzível

No CloudShell, dentro de /home/cloudshell-user/fiap-toggle-master-infra, manter a carga em um terminal:

```bash
DURATION_SECONDS=600 RATE_PER_SECOND=5 bash scripts/demo/load-validate.sh
```

Em outro terminal, confirmar o funcionamento e ativar a falha:

```bash
bash scripts/demo/auth-fault.sh status
bash scripts/demo/auth-fault.sh on
kubectl -n toggle-master get pods -l app=auth-service -w
```

Observar HTTP 500, ToggleMasterHigh5xxRate em Pending e depois Firing, incidente no PagerDuty, alerta no Discord e notificação do self-healing. O serviço deve ganhar novos pods e voltar a HTTP 200. Validar depois:

```bash
kubectl -n toggle-master rollout status deployment/auth-service --timeout=120s
bash scripts/demo/auth-fault.sh status
kubectl -n monitoring logs deploy/self-healing --since=10m
```

O estado esperado é fault_enabled=false nas duas novas réplicas. Não reiniciar manualmente durante a prova de self-healing. Se a automação falhar, encerrar o teste restaurando explicitamente o serviço:

```bash
bash scripts/demo/auth-fault.sh off
```

Registrar que houve intervenção manual nesse caso, investigar e repetir a prova. Nunca apresentar somente o log de patch como prova de recuperação: mostrar também pods Ready e respostas HTTP 200.

## Entrega

- PDF com nomes, RMs, usuários GitHub, links dos sete repositórios e branch de implantação.
- Arquitetura, escolhas técnicas e evidências de todos os requisitos.
- Link de vídeo acessível ao avaliador, com duração de até 25 minutos.
- Evidências desta sessão: [relatório de validação](VALIDACAO-INTEGRACOES-BRUNO.md) e pasta evidencias/.
- Antes de novo CI, renovar os três secrets AWS temporários nos cinco serviços quando necessário. O GitOps PAT atual expira em 21/11/2026.
- Após a apresentação, planejar a desmontagem com Terraform na ordem plataforma, infraestrutura e bootstrap, preservando as evidências e o estado até a revisão do plano de destruição. Nenhum destroy foi executado nesta validação.
