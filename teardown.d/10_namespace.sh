#!/bin/bash -eu

kubectl delete namespace $EXPERIMENT || echo "[*] Namespace deletion in progress?"
#kubectl delete namespace workbench-util || echo "[*] Util namespace deletion in progress?"
