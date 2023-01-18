#!/usr/bin/env bash

# Prepare metadata-store secrets for TAP multi-cluster footprint
# Collect token and ca-cert from cluster hosting TAP view profile
# Create secrets in namespace on cluster hosting TAP build profile

# Based upon procedure described here:
# * https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/scst-store-multicluster-setup.html
# * https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/scst-store-create-service-account.html
# * https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/scst-store-retrieve-access-tokens.html

# Inputs:
# * tap view cluster context name
# * tap build cluster context name


if [ -z "$1" ] && [ -z "$2" ]; then
	echo "Usage: prepare-metadata-store.sh {view-cluster-context-name} {build-cluster-context-name}"
	exit 1
fi

SECRETS_NAMESPACE=metadata-store-secrets

echo "switching to view context $1"
kubectl config use-context $1

echo "getting CA cert"
CA_CERT=$(kubectl get secret --namespace metadata-store ingress-cert -o jsonpath='{.data.ca\.crt}')
cat <<EOF > store_ca.yaml
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: store-ca-cert
  namespace: $SECRETS_NAMESPACE
data:
  ca.crt: $CA_CERT
EOF

echo "getting auth token"
AUTH_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d)


# Commands executed targeting cluster hosting TAP build profile

echo "switching to build context $2"
kubectl config use-context $2

kubectl create ns ${SECRETS_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f store_ca.yaml

kubectl delete secret store-auth-token -n ${SECRETS_NAMESPACE} \
  --ignore-not-found

kubectl create secret generic store-auth-token \
  --from-literal=auth_token=$AUTH_TOKEN -n ${SECRETS_NAMESPACE}
