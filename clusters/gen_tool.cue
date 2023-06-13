package clusters

import (
	"tool/file"
	"tool/cli"
	"encoding/yaml"
)

command: gen: {
	for clusterName, clusterCfg in cluster {
		"\(clusterName)": {

			for manifestName, manifest in clusterCfg.extraManifests {
				"\(manifestName)": {
					create: file.Create & {
						$dep:     command.gen.mkdirClusterConfigs.$done
						filename: "./generated_clusters/\(clusterCfg.environment)/\(manifestName).yaml"
						contents: yaml.Marshal(manifest)
					}
				}
			}

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
	for clusterName, clusterCfg in cluster {
		"\(clusterName)": {

			for manifestName, manifest in clusterCfg.extraManifests {
				"\(manifestName)": {
					print: cli.Print & {
						text: manifest
					}
				}
			}
		}
	}
}
