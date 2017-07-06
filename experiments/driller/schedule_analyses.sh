#!/bin/bash -e

export MEMORY_REQUEST=4Gi
export MEMORY_LIMIT=32Gi
export CPU_REQUEST=1000m
export CPU_LIMIT=1000m

gce_shared_ssh "ls -d /mnt/disks/mydisk/tarballs/*/" | parallel -j100 -k basename | parallel -j100 -k "make_pod -l results-{} \"/home/angr/.virtualenvs/angr/bin/python /home/angr/angr-dev/fuzzer/bin/analyze_result.py /shared/tarballs/{}\""
