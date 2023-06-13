package clusters

import (
	"github.com/akselleirv/multi-cluster-deployments/charts/argocd"
)

cluster: "p-mgmt": {
	environment: "prod"

	addon: {
		"argocd": argocd.#Chart & {
			values: "latest": _
		}
	}
}
