# Workbench - a distributed experimentation platform

This platform is designed to ease scientific experiments run in a distributed fashion through kubernetes.

## Installation

First, create the GKE cluster:

```
# create the cluster
gcloud container clusters create seagull --enable-ip-alias  --enable-private-nodes --no-enable-master-authorized-networks --create-subnetwork name=seagull-network --master-ipv4-cidr 172.16.0.0/28 --preemptible --enable-autoscaling --max-nodes=512 --min-nodes=0 --machine-type=n1-highmem-8

# if you change your mind about the pool later, recreate it
gcloud container node-pools delete default-pool
gcloud container node-pools create as-pre-4cpu-4gb-16hdd --cluster seagull --machine-type n1-highmem-4 --disk-size=16GB --enable-autoscaling --min-nodes 1 --max-nodes 1024 --num-nodes 1 --preemptible
gcloud container clusters resize seagull --size=1 --node-pool=as-pre-4cpu-4gb-16hdd
```

## Old docs

```
# Configure an experiment with persistent disk for storage
scripts/configure_experiment science -g sciencedisk:200GB -d ubuntu

# The above script creates a config file of environment variables -- let's source it
source experiments/science/config

# Actually create the experiment
scripts/make_experiment

# EXPERIMENT
cat your_dataset | parallel scripts/make_pod {} "/docker/path/to/testit.py --something={}"

# GO FASTER - ramp up to 16 instances!
scripts/gce_resize seagull preemptible-memory-32 16
# Or, alternatively, enable auto-scaling
gcloud alpha container clusters update seagull --enable-autoscaling --min-nodes=1 --max-nodes=16 --node-pool=preemptible-memory-32

# Check on the progress
PATH=$PATH:/path/to/workbench/scripts        # make the below easier to use
pod_names -r                                 # list running pods
pod_names -s                                 # list successful pods
pod_names -f "critical-.*"                   # list failed pods matching a regex
pod_states                                   # list pod counts by status
pod_names -r | pods_exec "hostname; ps -a"   # execute commands on all running pods

# Retrieve results from your shared drive, if that's how you roll
mkdir /tmp/results
scripts/gce_results_mount /tmp/results
cat /tmp/results/AWESOME_RESULTS

# Stop the experiment
scripts/nuke_experiment
scripts/gce_resize seagull preemptible-memory-32 0     # let's not pay
```

Additionally, code here can be mined for useful snippets:
- using a Google Compute Engine persistent disk for shared storage (thanks to https://github.com/kubernetes/kubernetes/tree/master/examples/volumes/nfs)
- creating and formatting a GCE persistent disk
- authentication against different docker registries

# Caveats

Be careful of GCE usage -- it's easy to rack up a big bill.
`scripts/gce_list` is helpful to quickly see what's running, but you're on your own there!
