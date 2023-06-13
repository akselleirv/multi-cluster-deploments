package clusters

import (
	"strings"
	"encoding/json"

	"github.com/akselleirv/multi-cluster-deployments/charts/grafana_agent"
)

cluster: [ClusterName=string]: #Cluster & {
	_name: ClusterName
}

#Cluster: {
	_name:       string & =~"\(strings.SliceRunes(environment, 0, 1))-.*"
	environment: "prod" | "test"

	// clusterMetadata: #ClusterMetadata

	addon: [string]: #addon
	#addon: {
		chartName: string
		values: [string]: _
	}

	addon: {
		"grafana_agent_events": grafana_agent.#Chart & {
			values: "latest": {
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
			values: "latest": {
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

	extraManifests: "argocd-secret-\(_name)": {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      _name
			namespace: "argocd"
			labels: "argocd.argoproj.io/secret-type": "cluster"
		}
		stringData: {
			name:   _name
			server: clusterMetadata.Server
			config: json.Marshal({
				tlsClientConfig: {
					insecure: false
					caData:   clusterMetadata.CAData
					keyData:  clusterMetadata.KeyData
					certData: clusterMetadata.CertData
				}
			})
		}
	}
}
