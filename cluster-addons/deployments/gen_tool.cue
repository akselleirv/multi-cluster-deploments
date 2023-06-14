package deployments

import (
	"tool/file"
	"tool/cli"
	"encoding/yaml"
)

command: gen: {
	// Remove all old configs
	removeAll: file.RemoveAll & {
		path: "./generated"
	}
	mkdir: file.MkdirAll & {
		$dep: removeAll.$done
		path: "./generated"
	}

	for appSetName, config in applicationSet {
		(appSetName): {
			create: file.Create & {
				$dep:     mkdir.$done
				filename: "./generated/appset-\(appSetName).yaml"
				contents: yaml.Marshal(config)
			}
			print: cli.Print & {
				$dep: create.$done
				text: "👉 \(appSetName)"
			}
		}
	}
}