argocd app create djtip \
  --repo https://github.com/rob-j-au/djtip \
  --path .cicd/helm/djtip \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace djtip
