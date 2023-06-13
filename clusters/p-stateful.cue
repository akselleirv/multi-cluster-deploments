package clusters

import (
	"github.com/akselleirv/multi-cluster-deployments/charts/redis_operator"
)

cluster: "p-stateful": {
	_name:       string
	environment: "prod"

	addon: {
		"redis_operator": redis_operator.#Chart & {
			values: "latest": _
		}
	}
}
