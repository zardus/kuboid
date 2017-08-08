#!/bin/bash -eu

echo "[*] Waiting for namespace deletion..."
while kubectl get namespace $EXPERIMENT
do
	sleep 1
done
