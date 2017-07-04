#!/bin/bash -eu

if [ "$RESULT_DEST" != "gce" ]
then
	echo "[*] Not creating GCE NFS rc (result destination is $RESULT_DEST)"
	exit
fi

echo "[*] Creating NFS share."

cat <<END > $WORKDIR/setup/gce_nfs_rc.yml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nfs-server-$GCE_DISK_NAME
  namespace: workbench-util
spec:
  replicas: 1
  selector:
    role: nfs-server-$GCE_DISK_NAME
  template:
    metadata:
      labels:
        role: nfs-server-$GCE_DISK_NAME
    spec:
      containers:
      - name: nfs-server-$GCE_DISK_NAME
        image: gcr.io/google-samples/nfs-server:1.1
        ports:
          - name: nfs
            containerPort: 2049
          - name: mountd
            containerPort: 20048
          - name: rpcbind
            containerPort: 111
        securityContext:
          privileged: true
        volumeMounts:
          - mountPath: /exports
            name: mypvc
      volumes:
        - name: mypvc
          gcePersistentDisk:
            pdName: $GCE_DISK_NAME
            fsType: ext4
END

cat <<END > $WORKDIR/setup/gce_nfs_service.yml
kind: Service
apiVersion: v1
metadata:
  name: nfs-service-$GCE_DISK_NAME
  namespace: workbench-util
spec:
  ports:
    - name: nfs
      port: 2049
    - name: mountd
      port: 20048
    - name: rpcbind
      port: 111
  selector:
    role: nfs-server-$GCE_DISK_NAME
END

#kubectl delete -f $WORKDIR/setup/gce_nfs_rc.yml || echo "[+] No NFS RC to delete..."
#kubectl delete -f $WORKDIR/setup/gce_nfs_service.yml || echo "[+] No NFS service to delete..."
kubectl create -f $WORKDIR/setup/gce_nfs_rc.yml || echo "[+] NFS RC already existed..."
kubectl create -f $WORKDIR/setup/gce_nfs_service.yml || echo "[+] NFS service already existed..."
