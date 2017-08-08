#!/bin/bash -eu

if [ -z "$DOCKER_USER" ]
then
	echo "[*] Skipping docker registry secret creation -- registry info not set"
	exit
fi

echo "[*] Creating docker registry secret $EXPERIMENT-secret!"
kubectl delete secret docker-secret -n $EXPERIMENT || echo "[+] No secret to delete..."
ARGS="--docker-username=$DOCKER_USER --docker-password=$DOCKER_PASS"
if [ -n "${DOCKER_SERVER-}" ]
then
	ARGS="$ARGS --docker-server=$DOCKER_SERVER"
fi
kubectl create secret docker-registry docker-secret --namespace $EXPERIMENT $ARGS --docker-email=go-away@asdf.com
