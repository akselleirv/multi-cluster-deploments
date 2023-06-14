package deployments

import (
	argov1alpha1 "github.com/argoproj/argo-cd/v2/pkg/apis/application/v1alpha1"
	"strings"
)

applicationSet: [string]: argov1alpha1.#ApplicationSet

applicationSet: [ID=string]: {
	_chartName:            *ID | string
	_chartNameUnderscored: strings.Replace(_chartName, "-", "_", -1)

	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ApplicationSet"
	metadata: {
		name: ID
	}
	spec: {
		generators: [{
			clusters: selector: matchLabels: "cluster.example.com/\(ID)": "enabled"
		}]
		template: {
			metadata: name: "\(ID)-{{ name }}"
			spec: {
				project: "default"
				source: {
					repoURL:        "https://github.com/akselleirv/multi-cluster-deploments.git"
					targetRevision: "HEAD"
					path:           *"charts/\(_chartNameUnderscored)" | string
					helm: {
						releaseName: string | *ID
						valueFiles: [
							"generated_values/{{ name }}_\(strings.Replace(ID, "-", "_", -1)).yaml",
						]
					}
				}
				destination: {
					server:    "{{ server }}"
					namespace: string | *ID
				}
				syncPolicy: {
					automated: {
						prune:    true
						selfHeal: true
					}
					syncOptions: [
						"CreateNamespace=true",
						"FailOnSharedResource=true",
					]
				}
			}
		}
	}
}