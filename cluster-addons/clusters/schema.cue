package clusters

import (
	"strings"

	"github.com/akselleirv/multi-cluster-deployments/charts/grafana_agent"
)

cluster: [ClusterName=string]: #Cluster & {
	_name: ClusterName
}

#Cluster: {
	_name:       string & =~"\(strings.SliceRunes(environment, 0, 1))-.*"
	environment: "prod" | "test"

	addon: [string]: #addon
	#addon: {
		chartName: string
		values:    _
	}

	addon: {
		"grafana_agent_events": grafana_agent.#Chart & {
			values: {
				clusterName: _name
				agentType:   "events"

				if environment == "prod" {
					targetHost: "https://loki.example.com/loki/api/v1/push"
				}
				if environment == "test" {
					targetHost: "https://loki.test.example.com/loki/api/v1/push"
				}
			}
		}
		"grafana_agent_logs": grafana_agent.#Chart & {
			values: {
				clusterName: _name
				agentType:   "logs"

				if environment == "prod" {
					targetHost: "https://loki.example.com/loki/api/v1/push"
				}
				if environment == "test" {
					targetHost: "https://loki.test.example.com/loki/api/v1/push"
				}
			}
		}
	}
}
