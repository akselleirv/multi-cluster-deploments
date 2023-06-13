package clusters

import (
	"tool/file"
	"tool/cli"
	"encoding/yaml"
	"encoding/json"
	"strings"
)

command: gen: {
	for clusterName, clusterCfg in cluster {
		"\(clusterName)": {

			let addonText = yaml.Marshal([ for addonName, _ in clusterCfg.addon {addonName}])
			print: cli.Print & {
				text: "☸ \(clusterName)\n--------------------------------------\n\(addonText)"
			}
			// Create all the cluster addon value files for the cluster
			for addonName, addonCfg in clusterCfg.addon {
				(addonName): {

					mkdir: file.MkdirAll & {
						path: "../charts/\(addonCfg.chartName)/generated_values/"
					}

					create: file.Create & {
						$dep:     mkdir.$done
						filename: "../charts/\(addonCfg.chartName)/generated_values/\(clusterName)_\(addonName).yaml"
						contents: yaml.Marshal(addonCfg.values)
					}
				}
			}
		}
	}
}

command: bootstrap: {
	manifests: {
		[ for clusterName, clusterCfg in cluster {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      clusterName
				namespace: "argocd"
				labels: {
					"argocd.argoproj.io/secret-type": "cluster"
					for addonName, _ in clusterCfg.addon {
						"cluster.example.com/\(strings.Replace(addonName, "_", "-", -1))": "enabled"
					}
				}
			}
			stringData: {
				name:   clusterName
				server: clusterCfg.clusterMetadata.Server
				config: json.Marshal({
					tlsClientConfig: {
						insecure: false
						caData:   clusterCfg.clusterMetadata.CAData
						keyData:  clusterCfg.clusterMetadata.KeyData
						certData: clusterCfg.clusterMetadata.CertData
					}
				})
			}

		}, {
			apiVersion: "argoproj.io/v1alpha1"
			kind:       "Application"
			metadata: {
				name:      "cluster-addons"
				namespace: "argocd"
				finalizers: [
					"resources-finalizer.argocd.argoproj.io",
				]
			}
			spec: {
				project: "default"
				destination: {
					namespace: "argocd"
					server:    "https://kubernetes.default.svc"
				}
				source: {
					path:           "deployments/generated"
					repoURL:        "https://github.com/akselleirv/multi-cluster-deploments.git"
					targetRevision: "main"
				}
				syncPolicy: automated: {
					prune:    true
					selfHeal: true
				}
			}

		}]

	}

	print: cli.Print & {
		text: yaml.MarshalStream(manifests)
	}
}
