package clusters

import (
	"tool/file"
	"tool/cli"
	"encoding/yaml"
)

command: gen: {
	for clusterName, clusterCfg in cluster {
		"\(clusterName)": {

			let addonText = yaml.Marshal([ for addonName, _ in clusterCfg.addon {addonName}])
			print: cli.Print & {
				text: "☸ \(clusterName)\n--------------------------------------\n\(addonText)"
			}
			// Create all the cluster addon value files for the cluster
			for addonName, addonCfg in clusterCfg.addon {
				(addonName): {

					mkdir: file.MkdirAll & {
						path: "../charts/\(addonCfg.chartName)/generated_values/"
					}

					create: file.Create & {
						$dep:     mkdir.$done
						filename: "../charts/\(addonCfg.chartName)/generated_values/\(clusterName)_\(addonName).yaml"
						contents: yaml.Marshal({
							// Remove the version from the values file
							for v, cfg in addonCfg.values {
								cfg
							}
						})
					}
				}
			}
		}
	}
}

command: bootstrap: {
	clusterManifests: [ for clusterName, clusterCfg in cluster for manifestName, manifest in clusterCfg.extraManifests {manifest}]
	print: cli.Print & {
		text: yaml.MarshalStream(clusterManifests)
	}
}
