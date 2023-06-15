# Multi-Cluster Deployments

## Goal: Define the applications that the various clusters should use while ensuring type safety, preventing death by copy/paste, and maintaining sanity.

# Folder Explanation

The three directories that you should care about in the repository are:

| Folder Name | Purpose                                                                                             |
| ----------- | --------------------------------------------------------------------------------------------------- |
| charts      | Defines the application with `Chart.yaml` and the values to be used in CUE.                         |
| clusters    | Defines all the clusters and the possible override values for each application.                     |
| deployments | The ApplicationSet definition which generates the ArgoCD Application based on the given generators. |


# Prerequisites

The following tools must be installed
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Helm](https://helm.sh/docs/intro/install/)
- [CUE](https://github.com/cue-lang/cue#download-and-install)


# Overview

A management cluster is created which will handle deployment to the worker clusters. In this demo only one worker cluster is created, however, the management cluster can handle several worker clusters. The management cluster uses [workload identity](https://azure.github.io/azure-workload-identity/docs/) to authenticate itself to the Kubernetes API server running in the worker clusters. 

![Overview](./assets/overview.svg)


## Setup management cluster

Create a resource group which will be used for installing all Azure resources
```
export RESOURCE_GROUP="multi-cluster-demo"
export LOCATION="norwayeast"
export SUBSCRIPTION="$(az account show --query id --output tsv)"
az group create --location $LOCATION --resource-group $RESOURCE_GROUP

```

Create an AKS cluster with workload identity, OIDC issuer and authentication using Azure AD.
```
export AKS_CLUSTER_MGMT="p-mgmt"
az aks create -g "${RESOURCE_GROUP}" -n "${AKS_CLUSTER_MGMT}" --enable-oidc-issuer --enable-workload-identity --node-count 1 --enable-aad
export AKS_OIDC_ISSUER="$(az aks show -n "${AKS_CLUSTER_MGMT}" -g "${RESOURCE_GROUP}" --query "oidcIssuerProfile.issuerUrl" -otsv)"
```


```
export USER_ASSIGNED_IDENTITY_NAME="mgmtArgoDemoIdentity"
export FEDERATED_IDENTITY_CREDENTIAL_NAME="mgmtArgoDemoFedIdentity"

# Create the managed identity for ArgoCD
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}" --subscription "${SUBSCRIPTION}"

# Get the principal ID which will be used for the ClusterRoleBinding
export USER_ASSIGNED_PRINCIPAL_ID="$(az identity show --resource-group "${RESOURCE_GROUP}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'principalId' -otsv)"


# Update the client id in the ArgoCD values file in  `clusters/p-mgmt.cue`
az identity show --resource-group "${RESOURCE_GROUP}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'clientId' -otsv

# Create a federated identity using the service account name, namespace and cluster information
export SERVICE_ACCOUNT_NAME="argocd-application-controller"
export SERVICE_ACCOUNT_NAMESPACE="argocd"
az identity federated-credential create --name ${FEDERATED_IDENTITY_CREDENTIAL_NAME} --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --audience api://AzureADTokenExchange

# Give ArgoCD cluster-admin for the management cluster
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
  name: "${USER_ASSIGNED_PRINCIPAL_ID}"
EOF
```

Update the cluster metadata file which contains metadata about the existing clusters.
```
echo "package clustermetadata\n" > clustermetadata/clustermetadata.gen.cue
cat ~/.kube/config | yq '.clusters[] | select(.name == env(AKS_CLUSTER_MGMT)) | { "cluster": {  env(AKS_CLUSTER_MGMT):  { "Server": .cluster.server, "CAData": .cluster."certificate-authority-data" } } }' | cue import -f yaml: - >> clustermetadata/clustermetadata.gen.cue
```
## Install ArgoCD

```
# Generate the Helm values file after the client ID has been updated. 
make gen
# Bootstrap the ArgoCD instance.
helm upgrade -i  argocd charts/argocd/ -n argocd --create-namespace -f charts/argocd/generated_values/p-mgmt_argocd.yaml

# The password for logging in.
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Setup worker cluster

```
export AKS_CLUSTER_WORKER="p-services"
az aks create -g "${RESOURCE_GROUP}" -n "${AKS_CLUSTER_WORKER}" --enable-oidc-issuer --enable-workload-identity --node-count 1 --enable-aad
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
The cluster-addons Application will reconcile the ApplicationSet files generated in the deployments folder. 

```
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
    path: cluster-addons/deployments/generated
    repoURL: https://github.com/akselleirv/multi-cluster-deploments.git
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```