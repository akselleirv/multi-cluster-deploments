package grafana_agent

#Chart: {
	chartName: "grafana_agent"
	values: latest?: {

		agentType:   "logs" | "events"
		clusterName: string
		targetHost:  string

		"grafana-agent": {
			controller: volumes: extra: [{
				name: "remote-write-token"
				projected: sources: [{
					serviceAccountToken: {
						audience:          "observability"
						expirationSeconds: 3600
						path:              "token"
					}
				}]
			}, ...]
			agent: {
				mounts: extra: [{
					name:      "remote-write-token"
					mountPath: "/run/secrets/remote-write"
					readOnly:  true
				}, ...]
				configMap: {
					create: false
					name:   "grafana-agent-\(agentType)"
					key:    "config.river"
				}
				extraEnv: [{
					name:  "CLUSTER_NAME"
					value: clusterName
				}, ...]
			}
		}

		if agentType == "logs" {
			"grafana-agent": {

				tolerations: [{
					operator: "Exists"
					effect:   "NoSchedule"
				}]

				agent: {
					mounts: varlog: true
					extraEnv: [_, {
						name:  "LOKI_ENDPOINT"
						value: targetHost
					}]
				}
			}
		}
		if agentType == "events" {
			"grafana-agent": {
				controller: {
					type: "statefulset"
					volumeClaimTemplates: [{
						metadata: name: "events"
						spec: {
							accessModes: ["ReadWriteOnce"]
							resources: requests: storage: "10Gi"
						}
					}]
				}
				agent: {
					storagePath: "etc/storage/agent"
					extraEnv: [_, {
						name:  "LOKI_ENDPOINT"
						value: targetHost
					}]
					extra: [{
						name:      "events"
						mountPath: "/etc/storage/agent"
					}]
				}
			}
		}
	}
}
