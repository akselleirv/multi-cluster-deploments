# Purpose:

## Define the applications that the various clusters should use while ensuring type safety, preventing death by copy/paste, and maintaining sanity.

# Folder Explanation

The three directories that you should care about in the repository are:

| Folder Name | Purpose                                                                                             |
|-------------|-----------------------------------------------------------------------------------------------------|
| charts      | Defines the application with `Chart.yaml` and the values to be used in CUE.                         |
| clusters    | Defines all the clusters and the possible override values for each application.                     |
| deployments | The ApplicationSet definition which generates the ArgoCD Application based on the given generators. |



# Steps:

## Setup clusters

```
kind create cluster --name p-services
kind create cluster --name p-statefulset
kind create cluster --name p-mgmt
```

## Install ArgoCD

```
kubectl ctx kind-p-mgmt
helm install argocd argo/argo-cd -n argocd --create-namespace -f ../charts/argocd/generated_values/p-mgmt_argocd.yaml
```

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