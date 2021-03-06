#!/bin/bash

# generate manifest of naftis for kubernetes deployment.
# usage: ./tool/genmanifest.sh config/in-cluster.toml

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# if no configuration file is specified, exit script.
if [[ -z $1 ]]; then
    echo "choose your configuration file"
    exit 1
fi

TAG=`$ROOT/tool/tag.sh`

# generate naftis.yaml from naftis Charts.
helm template install/helm/naftis --set api.image.repository=$HUB/naftis-api,api.image.tag=$TAG,ui.image.repository=$HUB/naftis-ui,ui.image.tag=$TAG --set-file api.config=$1 --name naftis --namespace naftis > naftis.yaml

# generate mysql.yaml from mysql Charts.
helm template install/helm/mysql --set persistence.storageClass="manual",mysqlRootPassword="WlRncGh3UWY5VQ==",mysqlUser="naftis",mysqlPassword="naftisIsAwesome" --set-file initializationFiles."naftis\.sql"=tool/naftis.sql  --name naftis --namespace naftis > mysql-cloud.yaml
echo -e '
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: naftis-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---

' > mysql.yaml
helm template install/helm/mysql --set persistence.storageClass="manual",mysqlRootPassword="WlRncGh3UWY5VQ==",mysqlUser="naftis",mysqlPassword="naftisIsAwesome" --set-file initializationFiles."naftis\.sql"=tool/naftis.sql  --name naftis --namespace naftis >> mysql.yaml

