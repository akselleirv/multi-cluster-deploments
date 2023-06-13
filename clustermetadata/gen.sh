rm clustermetadata.gen.cue
for cluster in $(kind get clusters); do
    echo $cluster
    kind get kubeconfig --name $cluster | yq '{ "cluster": { .clusters.0.name: {"Server": .clusters.0.cluster.server, "CAData": .clusters.0.cluster."certificate-authority-data", "KeyData": .users.0.user."client-key-data", "CertData": .users.0.user."client-certificate-data" } } }' | cue import -f yaml: - >> clustermetadata.gen.cue
done