helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm -n canal upgrade --install rabbitmq-cluster bitnami/rabbitmq -f deepin-values.yml
