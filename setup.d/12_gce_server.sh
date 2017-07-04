#!/bin/bash -eux

exit

if [ "$RESULT_DEST" != "gce" ]
then
	echo "[*] Not creating GCE NFS server (result destination is $RESULT_DEST)"
	exit
fi

BOX=$EXPERIMENT-nfs

if gcloud compute instances list 2>&1| grep -q $BOX
then
	echo "[*] GCE NFS server already exists..."
	exit
fi

echo "[*] GCE NFS server creation commencing!"

gcloud compute instances create $BOX --machine-type f1-micro
gcloud compute instances attach-disk --disk=$GCE_DISK_NAME --device-name results $BOX
gcloud compute ssh $BOX --command "\
	sudo mkdir -p /exports/results && \
	echo '/dev/disk/by-id/google-results /exports/results ext4 discard,defaults,nobarrier,errors=remount-ro 0 1' | \
		sudo tee -a /etc/fstab && \
	sudo mount /exports/results && \
	yes | sudo apt-get install nfs-kernel-server && \
	echo '/exports/results/ *(rw,async,no_root_squash)' | sudo tee -a /etc/exports && \
	sudo /etc/init.d/nfs-kernel-server restart"

echo "[*] GCE NFS server creation complete!"
