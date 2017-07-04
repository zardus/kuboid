#!/bin/bash -eu

cat <<END > $WORKDIR/setup/namespace.yml
kind: Namespace
metadata:
  name: $EXPERIMENT
  labels:
    name: $EXPERIMENT
END

cat <<END > $WORKDIR/setup/namespace-util.yml
kind: Namespace
metadata:
  name: workbench-util
  labels:
    name: workbench-util
END

kubectl create -f $WORKDIR/setup/namespace.yml || echo "[+] Namespace already exists?"
kubectl create -f $WORKDIR/setup/namespace-util.yml || echo "[+] Util namespace already exists?"
