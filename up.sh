#!/bin/bash
pwd="$(dirname "${0}")"

echo ${pwd}

echo "Starting local dev environment (Starting minikube)"
minikube start

kubectl create namespace elmo-garden


echo "Updating hosts file"

#INGRESSES=$(kubectl --context=minikube --all-namespaces=true get ingress -o jsonpath='{.items[*].spec.rules[*].host}')
MINIKUBE_IP=$(minikube ip)

HOSTS_ENTRY="$MINIKUBE_IP local.elmodev.com"

if grep -Fq "$MINIKUBE_IP" /etc/hosts > /dev/null
then
    sudo sed -i '' "s/^$MINIKUBE_IP.*/$HOSTS_ENTRY/" /etc/hosts
    echo "Updated hosts entry"
else
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
    echo "Added hosts entry"
fi

echo "Creating local TLS certificates and deploying to minikube"

mkcert -cert-file local-elmodev.pem -key-file local-elmodev-key.pem 'local.elmodev.com' '*.local.elmodev.com' '*.crt.local.elmodev.com' '*.survey.local.elmodev.com' '*.recruitmentapi.local.elmodev.com'
mkcert -install

kubectl delete secret tls-local-elmodev --namespace elmo-garden
kubectl create secret tls tls-local-elmodev --key "${pwd}"/local-elmodev-key.pem --cert "${pwd}"/local-elmodev.pem --namespace elmo-garden

rm -rf local-*


echo "Sleeping for 15 seconds...Waiting for minikube"
sleep 15

echo "Running garden deploy - This will deploy the stack"
garden deploy

echo "Running garden dev - This will listen for code changes and automatically update the container. If you dont want automatic code changes."
echo "You can get out of it and run garden deploy when you want the code to update."
garden dev

