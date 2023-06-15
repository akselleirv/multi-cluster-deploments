## Import YAML

```
cue import --force --package example appset.yaml

cue import --force --recursive --package example appset.yaml

cue import --force --recursive --package example  -l 'strings.ToCamel(kind)' -l metadata.name appset.yaml

# fix typo in example yaml
```
## Fetching the ArgoCD CUE definitions

```
go mod init github.com/akselleirv/import-example
cue mod init github.com/akselleirv/import-example

go get k8s.io/apimachinery
go get github.com/argoproj/argo-cd/v2
cue get go github.com/argoproj/argo-cd/v2/pkg/apis/application/v1alpha1
```