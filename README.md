# Purpose:

## Define the applications that the various clusters should use while ensuring type safety, preventing death by copy/paste, and maintaining sanity.

# Folder Explanation

The three directories that you should care about in the repository are:

| Folder Name | Purpose                                                                                             |
| ----------- | --------------------------------------------------------------------------------------------------- |
| charts      | Defines the application with `Chart.yaml` and the values to be used in CUE.                         |
| clusters    | Defines all the clusters and the possible override values for each application.                     |
| deployments | The ApplicationSet definition which generates the ArgoCD Application based on the given generators. |



# Steps:


## Setup management cluster
```
export RESOURCE_GROUP="multi-cluster-demo"
export LOCATION="norwayeast"
export SUBSCRIPTION="$(az account show --query id --output tsv)"
az group create --location $LOCATION --resource-group $RESOURCE_GROUP

export AKS_CLUSTER_MGMT="p-mgmt"

az aks create -g "${RESOURCE_GROUP}" -n "${AKS_CLUSTER_MGMT}" --enable-oidc-issuer --enable-workload-identity --node-count 1

# Output the OIDC issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n "${AKS_CLUSTER_MGMT}" -g "${RESOURCE_GROUP}" --query "oidcIssuerProfile.issuerUrl" -otsv)"

export USER_ASSIGNED_IDENTITY_NAME="mgmtArgoDemoIdentity"
export FEDERATED_IDENTITY_CREDENTIAL_NAME="mgmtArgoDemoFedIdentity"
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}" --subscription "${SUBSCRIPTION}"
export USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group "${RESOURCE_GROUP}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'clientId' -otsv)"

# Update the client id in the ArgoCD values file in  `clusters/p-mgmt.cue`

export SERVICE_ACCOUNT_NAME="argocd-application-controller"
export SERVICE_ACCOUNT_NAMESPACE="argocd"

az identity federated-credential create --name ${FEDERATED_IDENTITY_CREDENTIAL_NAME} --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --audience api://AzureADTokenExchange

az aks get-credentials -n $AKS_CLUSTER_MGMT -g "${RESOURCE_GROUP}"

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "${USER_ASSIGNED_CLIENT_ID}"
EOF

echo "package clustermetadata\n" > clustermetadata/clustermetadata.gen.cue
cat ~/.kube/config | yq '.clusters[] | select(.name == env(AKS_CLUSTER_MGMT)) | { "cluster": {  env(AKS_CLUSTER_MGMT):  { "Server": .cluster.server, "CAData": .cluster."certificate-authority-data" } } }' | cue import -f yaml: - >> clustermetadata/clustermetadata.gen.cue
```

## Install ArgoCD

```
make gen
helm upgrade -i  argocd charts/argocd/ -n argocd --create-namespace -f charts/argocd/generated_values/p-mgmt_argocd.yaml

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Setup worker cluster

```
export AKS_CLUSTER_WORKER="p-services"
az aks create -g "${RESOURCE_GROUP}" -n "${AKS_CLUSTER_WORKER}" --enable-oidc-issuer --enable-workload-identity --node-count 1
az aks get-credentials -n $AKS_CLUSTER_WORKER -g "${RESOURCE_GROUP}"

# Update metadata file

cat ~/.kube/config | yq '.clusters[] | select(.name == env(AKS_CLUSTER_WORKER)) | { "cluster": {  env(AKS_CLUSTER_WORKER):  { "Server": .cluster.server, "CAData": .cluster."certificate-authority-data" } } }' | cue import -f yaml: - >> clustermetadata/clustermetadata.gen.cue

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "${USER_ASSIGNED_CLIENT_ID}"
EOF
```

### Add cluster-addons Argo applicaton to management cluster

kubectl ctx p-mgmt

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-addons
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  source:
    path: deployments/generated
    repoURL: https://github.com/akselleirv/multi-cluster-deploments.git
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

## Install cluster access in mgmt cluster

```
cue cmd bootstrap | kubectl apply -f -
```


## Import Go structs

```
go get k8s.io/apimachinery
go get github.com/argoproj/argo-cd/v2
cue get go github.com/argoproj/argo-cd/v2/pkg/apis/application/v1alpha1
```