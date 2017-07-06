#!/bin/bash -e

export MEMORY_REQUEST=4Gi
export MEMORY_LIMIT=32Gi
export CPU_REQUEST=1000m
export CPU_LIMIT=1000m

gce_shared_ssh '
cd /mnt/disks/mydisk/tarballs
for i in *.tar.gz;
do
	NEWNAME=$(tar tzf $i | head -n1 | tr -d /); \
	[ $i != $NEWNAME.tar.gz ] && mv -v $i $NEWNAME.tar.gz; \
	[ -e $NEWNAME ] && echo Skipping $i... && continue; \
	echo Extracting $i... ;
	{ tar -xzf $NEWNAME.tar.gz & }; \
done ; \
echo "Waiting for extraction completion." \
wait ; \
echo "ALL DONE." \
'
