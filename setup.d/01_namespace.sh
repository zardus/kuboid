#!/bin/bash -eu

cat <<END > $WORKDIR/setup/namespace.yml
kind: Namespace
metadata:
  name: $EXPERIMENT
  labels:
    name: $EXPERIMENT
END

kubectl create -f $WORKDIR/setup/namespace.yml || echo "[+] Namespace already exists?"
