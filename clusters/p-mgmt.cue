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
			values: "argo-cd": configs: tls: certificates: {for name, cfg in clustermetadata.cluster {
				"https://\(strings.Trim(name, "kind-"))-control-plane": cfg.CAData
				} 
			}
		}
	}
}
