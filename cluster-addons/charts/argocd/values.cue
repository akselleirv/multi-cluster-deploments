package argocd

#Chart: {
	chartName: "argocd"
	values: {
		clientID: string
		clusters: [...{
			name:   string
			server: string
			caData: string
			addons: [string]: string
		}]
		"argo-cd": {
			chart: enabled: true

			controller: {
				podLabels: "azure.workload.identity/use": "true"
				serviceAccount: annotations: "azure.workload.identity/client-id": clientID
				initContainers: [{
					name:  "download-kubelogin"
					image: "alpine:3.8"
					command: ["sh", "-c"]
					workingDir: "/custom-tools"
					args: ["wget -qO kubelogin.zip https://github.com/Azure/kubelogin/releases/download/v0.0.30/kubelogin-linux-amd64.zip && unzip kubelogin.zip && mv ./bin/linux_amd64/kubelogin . && chmod +x kubelogin"]
					volumeMounts: [{
						mountPath: "/custom-tools"
						name:      "custom-tools"
					}]
				}]
				volumeMounts: [{
					mountPath: "/usr/local/bin/kubelogin"
					name:      "custom-tools"
					subPath:   "kubelogin"
				}]

				volumes: [{
					name: "custom-tools"
					emptyDir: {}
				}]
			}
		}
	}
}
