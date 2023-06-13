package clusters

import (
	"github.com/akselleirv/multi-cluster-deployments/charts/redis_operator"
)

cluster: "t-stateful": {
	_name:       string
	environment: "test"

	addon: {
		"redis_operator": redis_operator.#Chart & {
			values: "latest": _
		}
	}
}
