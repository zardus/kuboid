#!/bin/bash -eu

kubectl delete namespace $EXPERIMENT || echo "[*] Namespace deletion in progress?"
