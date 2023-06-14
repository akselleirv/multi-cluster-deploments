package deployments

applicationSet: argocd: {}

applicationSet: "grafana-agent-events": {
	_chartName: "grafana-agent"
	spec: template: spec: {
		destination: namespace: "observability"
		source: helm: skipCrds: true
	}
}

applicationSet: "grafana-agent-logs": {
	_chartName: "grafana-agent"
	spec: template: spec: {
		destination: namespace: "observability"
		source: helm: skipCrds: true
	}
}
