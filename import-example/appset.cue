package example

import (
	yaml656e63 "encoding/yaml"
	json656e63 "encoding/json"
)

applicationSet: guestbook: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "ApplicationSet"
	metadata: {
		name:      "guestbook"
		namespace: "argocd"
	}
	spec: {
		generators: [{
			clusters: selector: matchLabels: type: "production"
		}]
		template: {
			metdata: name: "{{name}}-guestbook"
			spec: {
				project: "my-project"
				source: {
					repoURL:        "https://github.com/argoproj/argocd-example-apps/"
					targetRevision: "HEAD"
					path:           "guestbook"
					helm: {
						values: yaml656e63.Marshal(_cue_values)
						let _cue_values = {
							example: true
							config:  json656e63.Marshal(_cue_config)
							let _cue_config = {
								some_values: [1, 2, 3]
							}
						}
					}
				}

				destination: {
					server:    "{{server}}"
					namespace: "guestbook"
				}
			}
		}
	}
}
