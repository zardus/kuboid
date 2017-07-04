#!/bin/bash -eu

if [ "$RESULT_DEST" != "nfs" -a "$RESULT_DEST" != "gce" ]
then
	echo "[*] Not creating NFS share (result destination is $RESULT_DEST)"
	exit
fi

if [ "$RESULT_DEST" == "gce" ]
then
	NFS_SERVER=$(kubectl get services -n $EXPERIMENT | tail -n1 | awk '{print $2}')
	NFS_PATH=/exports/results
fi

echo "[*] Creating NFS share."

cat <<END > $WORKDIR/setup/nfs_pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $EXPERIMENT-nfs
  namespace: $EXPERIMENT
spec:
  capacity:
    storage: 1Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: $NFS_SERVER
    path: "$NFS_PATH"
END

cat <<END > $WORKDIR/setup/nfs_pvc.yml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $EXPERIMENT-nfs
  namespace: $EXPERIMENT
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
  volumeName: $EXPERIMENT-nfs
END

kubectl delete -n $EXPERIMENT -f $WORKDIR/setup/nfs_pv.yml || echo "[+] No PV to delete..."
kubectl delete -n $EXPERIMENT -f $WORKDIR/setup/nfs_pvc.yml || echo "[+] No PVC to delete..."
kubectl create -n $EXPERIMENT -f $WORKDIR/setup/nfs_pv.yml
kubectl create -n $EXPERIMENT -f $WORKDIR/setup/nfs_pvc.yml
