#!/bin/bash -eu

[ "$RESULT_DEST" != "gce" ] && exit

RESULT_INSTANCE=$(gcloud compute disks describe $GCE_DISK_NAME | grep -A1 users | tail -n1 | sed -e s=.*/==)
[ -z "$RESULT_INSTANCE" ] && exit
gcloud compute instances detach-disk --disk $GCE_DISK_NAME $RESULT_INSTANCE
