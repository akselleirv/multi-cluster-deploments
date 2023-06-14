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
						contents: yaml.Marshal(addonCfg.values)
					}
				}
			}
		}
	}
}
