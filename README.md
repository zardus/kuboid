# kuboid - making kubernetes less painful for large experiments

This platform is designed to ease scientific experiments run in a distributed fashion through kubernetes.
Distributed scientific experiments (at least, the ones this framework targes) should be defined by the following properties:

- they are parallelizable
- they can be run from a common docker image, with just a different command argument (i.e., a program name or a URL) definiting different members of the experiment dataset
- they produce output that can either be dumped on a shared NFS drive or simply exfiltrated via stdout

kuboid is made to make such experiments easier by enabling mass creation, management, and deletion of kubernetes pods.
It assumes that you are the master of your own kubernetes workspace, and works to try to minimize your pain in wrangling your experiments.

## The scripts

The scripts are designed to reside in your path:

```
export PATH=/path/to/workbench/scripts:$PATH
```

Alternatively, you can run `setup.sh`, which will put that in your bashrc.

There are some useful scripts:

**Pod Creation**

- `pod_create` - a super simple interface for the creation of a Kubernetes pod! USE THIS!! Also read the help: it has some cool features, like the ability to skip pod creation if you already have completion logs from that pod.
- `pods_create` - a helper to create multiple pods. Takes commands as lines on stdin and pushes them to `pod_create`

**Pod Management**

- `pod_names` - retrieves the names of pods that fit certain status criteria or regexes. See the help for more info. This is mainly meant to be piped into various other pod management commands.
- `pod_states` - gets a summary of the states of various pods
- `pod_runtime` - retrieves the runtime of a pod
- `pods_runtime` - reads a list of pods from stdin (for example, from `pod_names`), and runs them through `pod_runtime`
- `pod_exec` - runs a command on a pod
- `pods_exec` - takes a list of pods from stdin (for example, from `pod_names`), and runs a command on all of them
- `pod_shell` - drops a shell in a pod
- `pod_describe` - prints the kubernetes description of a pod
- `pods_describe` - takes a list of pods from stdin and prints their descriptions
- `pod_logs` - prints the logs of a pod
- `pods_logs` - takes a list of pods from stdin and prints all their logs
- `pod_savelog` - saves the logs of a pod to a given directory. This is super useful with the "log check" functionality of `pod_create -l` to avoid scheduling duplicate pods
- `pods_savelog` - takes a list of pods from stdin (i.e., completed pods with `pod_names -c`) and saves their logs to a directory. Quite useful with `pod_create -l`.
- `pod_loggrep` - greps through the logs of a pod for a regex, and prints out the pod name if there is a match
- `pods_loggrep` - takes a list of pods from stdin and greps them for a regex, printing out the pod names that match
- `pod_delete` - deletes a pod. Make sure to save the pod's logs, as this deletes them.
- `pods_delete` - takes a list of pods via stdin (for example, from `pod_names`), and deletes them

**Node Management**

- `node_names` - gets the names of the kubernetes nodes in the cluster
- `node_describe` - describes a node
- `nodes_describe` - describes nodes from stdin
- `node_exec` - executes a command on a node. Requires GCE ssh access.
- `nodes_exec` - executes a command on many nodes. Requires GCE ssh access.
- `nodes_idle`
- `nodes_used`

**GCE Scripts**

- `gce_list`
- `gce_resize`
- `gce_shared_mount`
- `gce_shared_ssh`

**Helper Scripts**

- `namespace_config` - creates a kubernetes config file, authenticated by token, and customized for a given namespace
- `kubesanitize` - sanitizes any string into a form acceptable for a kubernetes entity name (such as a pod)
- `afl_tweaks` - applies necessary tweaks to nodes to run AFL. Requires direct GCE ssh access.
- `set_docer_secret` - sets the dockerhub credentials with which to pull images
- `monitor_experiment` - monitors an experiment, saving logs as pods complete. BROKEN.

## Examples

Here is an example:

```
# schedule some pods with a prefix of "echo"
seq 1 10 | parallel echo echo {} | pods_create -p echo

# save off the logs of the completed ones
pod_names -c | pods_savelogs my_logs

# using the -l option, pods_create is smart enough not to schedule pods that we already saved
seq 1 10 | parallel echo echo {} | pods_create -l my_logs -p echo

# delete the completed pods
pod_names -c | pods_delete

# delete all pods
pod_names | pods_delete
```

## Cluster Creation

Here's an example to create a cluster:

```
# create the cluster
gcloud container clusters create seagull --enable-ip-alias  --enable-private-nodes --no-enable-master-authorized-networks --create-subnetwork name=seagull-network --master-ipv4-cidr 172.16.0.0/28 --preemptible --enable-autoscaling --max-nodes=512 --min-nodes=0 --machine-type=n1-highmem-8

# if you change your mind about the pool later, recreate it
gcloud container node-pools delete default-pool
gcloud container node-pools create as-pre-4cpu-4gb-16hdd --cluster seagull --machine-type n1-highmem-4 --disk-size=16GB --enable-autoscaling --min-nodes 1 --max-nodes 1024 --num-nodes 1 --preemptible
gcloud container clusters resize seagull --size=1 --node-pool=as-pre-4cpu-4gb-16hdd

# if you want to make a shareable kube config
gcloud container clusters get-credentials seagull
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
get_config -n some_namespace
```
