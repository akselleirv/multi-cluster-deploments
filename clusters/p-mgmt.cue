package clusters

import (
	"strings"

	"github.com/akselleirv/multi-cluster-deployments/charts/argocd"
	"github.com/akselleirv/multi-cluster-deployments/clustermetadata"
)

cluster: "p-mgmt": {
	environment: "prod"

	addon: {
		"argocd": argocd.#Chart & {
			values: {
				clientID: "1cf636b4-6914-405f-86f0-337691163a66"
				clusters: [ for clusterName, clusterCfg in cluster{
					_clusterMetadata: clustermetadata.cluster[clusterName]
					name:             clusterName
					caData:           _clusterMetadata.CAData
					server:           _clusterMetadata.Server
					addons: {
						"argocd.argoproj.io/secret-type": "cluster"
						for addonName, _ in clusterCfg.addon {
							"cluster.example.com/\(strings.Replace(addonName, "_", "-", -1))": "enabled"
						}
					}
				}]
			}
		}
	}
}
