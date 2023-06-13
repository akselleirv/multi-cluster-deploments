package argocd

#Chart: {
	chartName: "argocd"
	values: {
		"argo-cd": {
			chart: enabled: true
			configs: tls: certificates: _
		}
	}
}
