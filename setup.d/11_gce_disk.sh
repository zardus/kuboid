#!/bin/bash -eux

if [ "$RESULT_DEST" != "gce" ]
then
	echo "[*] Not creating GCE disk (result destination is $RESULT_DEST)"
	exit
fi

if gcloud compute disks list 2>&1| grep -q $GCE_DISK_NAME
then
	echo "[*] GCE disk already exists..."
	exit
fi

BOX=$EXPERIMENT-formatter

echo "[*] GCE disk creation commencing!"

gcloud compute disks create --size ${GCE_DISK_SIZE+200GB} $GCE_DISK_NAME
gcloud compute instances create $BOX
gcloud compute instances attach-disk --disk=$GCE_DISK_NAME --device-name results $EXPERIMENT-formatter
gcloud compute ssh $BOX --command " \
	sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-results && \
	sudo mount /dev/disk/by-id/google-results /mnt && \
	sudo chmod 777 /mnt && \
	sudo mkdir /mnt/results && \
	sudo chown 1000.1000 /mnt/results && \
	sudo umount /mnt"
gcloud compute instances detach-disk --disk $GCE_DISK_NAME $BOX
yes | gcloud compute instances delete $BOX

echo "[*] GCE disk creation complete!"
