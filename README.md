# kuboid - making kubernetes less painful for large experiments

This platform is designed to ease scientific experiments run in a distributed fashion through kubernetes.
Distributed scientific experiments (at least, the ones this framework targets) should be defined by the following properties:

- they are parallelizable
- they can be run from a common docker image, with just a different command argument (i.e., a program name or a URL) defining different members of the experiment dataset
- they produce output that can either be dumped on a shared NFS drive or simply exfiltrated via stdout

kuboid is made to make such experiments easier by enabling mass creation, management, and deletion of kubernetes pods.
It assumes that you are the master of your own kubernetes workspace, and works to try to minimize your pain in wrangling your experiments.

If all goes well, there should be an NFS-shared directory mounted in `/shared` in every pod!

## QUICKSTART

If you want to get started quick:

### Step 0: get your kube configuration file

You need a kubernetes config file to use kuboid.
The config file contains all you need to schedule tasks on a kubernetes cluster.
This is an example kube config file, for reference:

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: SECRET==
    server: https://CLUSTER_IP
  name: YOUR_CLUSTER_NAME
contexts:
- context:
    cluster: YOUR_CLUSTER_NAME
    namespace: NAMESPACE_FOR_YOUR_EXPERIMENTS
    user: YOUR_CLUSTER_NAME
  name: YOUR_CLUSTER_NAME
current-context: YOUR_CLUSTER_NAME
kind: Config
preferences: {}
users:
- name: YOUR_CLUSTER_NAME
  user:
    token: SECRET==

```

This cluster can either be created by you (see `Cluster Creation` below) or maintained by someone else.
Normally, you'd ask your professor or lab cloud admin for it, and they'd create it with the `kuboid/admin/create_kubeconfig` script.
You don't have to worry about this, but the important thing here is `namespace: NAMESPACE_FOR_YOUR_EXPERIMENTS`: it'll keep your experiments confined to your namespace, and will let multiple users use the same cluster without too much chaos!

### Step 1: dockerize your experiment!

This is easy!
Simply create a dockerfile that has all the code your experiment needs.
You can also dump the data in there, but that'll likely make your docker image big and unwieldy.
My advice is to keep the data somewhere else.
For example, I pushed the CGC binaries I used to experiment on to a GitHub repo (https://github.com/zardus/cgc-bins) and used to pull them down in my experiment script.

When your dockerfile is done, you'll push it to dockerhub:

```
docker build -t my_dockerhub_username/my_experiment /path/to/my/code
docker login my_dockerhub_username
docker push my_dockerhub_username/my_experiment
```

Now you're ready to rock!

### Step 2: get a list of tasks together!!

To run your tasks, kuboid will cause kubernetes to execute them with your task provided on the commandline (so make sure your `CMD` in your dockerfile can deal with that).
Kuboid will take each line in a task file (or stdin) as a task.
For example:

```
# cat /my/echo/experiments
echo 1
echo 2
echo 3
echo 4
```

Now you're ready to roll!

### Step 3: run the experiment!!!

Kuboid provides a master script that'll run and monitor your experiment:

```
/path/to/kuboid/scripts/monitor_experiment -k /path/to/my/kube/config -f /my/echo/experiments -l kuboid-logs -i my_dockerhub_username/my_experiment
```

`monitor_experiment` will schedule your tasks into kubernetes pods, monitor them for completion, save the logs of your completed pods, and reschedule ones that get deleted because of system failures (or node preemption on cloud services).
You can also omit the `-f` option to make kuboid read tasks from stdin, omit the `-k` option to have kubernetes use either the `KUBECONFIG` environment variable or the `~/.kube/config` file for the kubernetes configuration, and omit the `-l` option to default to the log directory `kuboid-logs`.
More tasks can be added to the task file (or to stdin) at runtime!

As tasks complete (and only when they complete), their log output will be saved into `kuboid-logs` (or whatever directory you provide with `-l`).
This is important: not only can you get the results of your experiments from these logs, but kuboid will consult this directory to figure out whether a pod disappeared because it completed, or whether it disappeared due to a node failure.
If a log for a pod exists in this directory, the associated task will *not* be (re)run.

### Detour: other useful scripts

Kuboid also provides a lot of scripts for checking on and managing your nodes, other than `monitor_experiment`.
If you are interested, they are in the `kuboid/scripts` directory:

- `pod_create` - a super simple interface for the creation of a Kubernetes pod! USE THIS!! Also read the help: it has some cool features, like the ability to skip pod creation if you already have completion logs from that pod.
- `pods_create` - a helper to create multiple pods. Takes commands as lines on stdin and pushes them to `pod_create`
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
- `name_pod` - takes the same arguments as `pod_create` and emits the name of the resulting pod.
- `name_pods` - takes the same arguments as `pods_create` and emits the name of the resulting pods.
- `kubesanitize` - sanitizes any string into a form acceptable for a kubernetes entity name (such as a pod)
- `monitor_experiment` - monitors an experiment, saving logs as pods complete. BROKEN.
- `set_docer_secret` - sets the dockerhub credentials with which to pull images
- `mount_nfs` - mounts the cluster's NFS share on the host filesystem

Now you're ready for SCIENCE!

### Step 4: getting the results!!!!

There are three ways to get the results of your experiments:

1. Have your results output to stdout in the docker container.
   Your stdout will then be saved into the log directory and you can grab them from there.
2. In a cluster created kuboid, the `/shared` directory is shared by all pods.
   You can dump your results there if they are large, and mount them magically on your _local machine_ using `kuboid/scripts/mount_nfs`!
3. You can have your code in your docker image upload results somewhere as they complete.
   This is generally a pain, because you have to somehow pass credentials around.

My recommendation is: if your results are small and text-based (i.e., number of branches explored in symbolic execution), get them via stdout, and if they're big (i.e., all inputs found using fuzzing), get them via NFS.
Good luck!

### A note about preemption.

If your kubernetes cluster is running on preemtable nodes (for example, in GKE), your pods might just vanish.
In fact, that is a reason for the internal complexity of kuboid, as it is.
The longer-running your tasks are, the more likely this will be to happen to any given pod.
Kuboid will reschedule your pods if the node they are running on gets preempted (this is why we don't save logs until a pod completes, in fact), but for long-running tasks, you might want to save snapshots into `/shared` on a regular basis, and restart from them if your pod is rescheduled.
That's something that has to happen in your code (for example, by periodically tarring an AFL directory to `/shared` and untarring it when the pod starts up).


## Setup

To run the kuboid scripts, you will first need to install kubectl; follow the [official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for details on how to do this.

You can then add the path to kuboid scripts to your `$PATH` environment variable:

```
export PATH=/path/to/kuboid/scripts:$PATH
```

Alternatively, you can run `setup.sh`, which will put that in your `.bashrc` file to automatically run when you launch a new shell.

## Cluster Administration

There are also scripts to make the cluster admin's life simpler.

- `node_names` - gets the names of the kubernetes nodes in the cluster
- `node_describe` - describes a node
- `nodes_describe` - describes nodes from stdin
- `node_exec` - executes a command on a node. Requires GCE ssh access.
- `nodes_exec` - executes a command on many nodes. Requires GCE ssh access.
- `nodes_idle` - shows a list of nodes that have no pods running on them
- `nodes_used` - shows a list of nodes that have pods running on them
- `gce_list` - shows an accounting of your GCE resources (needs you to configure gcloud).
   If you run your cluster on GCE, I recommend this to avoid spending all your money!
- `gce_resize`
- `gce_shared_mount`
- `gce_shared_ssh`
- `configure_nfs_server` - creates a shared GCE disk and configures the kubernetes NFS server and replication controller
- `configure_nfs_volume` - creates the NFS volume and volume claim in the pod namespace
- `create_kubeconfig` - creates a kubernetes config file, authenticated by token, and customized for a given namespace.
  If necessary, this script will create the necessary namespace, NFS volume, etc.
- `afl_tweaks` - applies necessary tweaks to nodes to run AFL.
  Requires direct GCE ssh access.

## More Examples

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


# make a list of pod commands
echo sleep 10 >> mypods
echo sleep 20 >> mypods
echo sleep 30 >> mypods
mkdir completed_logs
# keep scheduling the uncompleted ones (if they're pre-empted)
watch 'cat mypods | pods_create -p arbiter -l completed_logs'
# keep getting the completed logs and removing them
watch 'pod_names -c | pods_savelog my_logs | pods_delete'
# keep a log of errored and OOM pods
watch 'pod_names -eof >> errored_pods'
```

## Cluster Creation

Here's an example to create a cluster:

```
# create the cluster (private IPs --- NO INTERNET ACCESS)
gcloud container clusters create seagull --enable-ip-alias  --enable-private-nodes --no-enable-master-authorized-networks --create-subnetwork name=seagull-network --master-ipv4-cidr 172.16.0.0/28 --preemptible --enable-autoscaling --max-nodes=512 --min-nodes=0 --machine-type=n1-highmem-8
# create the cluster (public IPs)
gcloud container clusters create seagull --preemptible --disk-size=100GB --enable-autoscaling --min-nodes=1 --max-nodes=512 --num-nodes 1 --machine-type=n1-highmem-8

# if you change your mind about the pool later, recreate it
gcloud container node-pools delete default-pool
gcloud container node-pools create as-pre-8cpu-64gb-100hdd --cluster seagull --preemptible --disk-size=100GB --enable-autoscaling --min-nodes 1 --max-nodes 500 --num-nodes 1 --machine-type n2-highmem-8

gcloud container clusters resize seagull --size=1 --node-pool=as-pre-8cpu-64gb-100hdd

# create the NFS configuration
create_nfs_server

# if you want to make a shareable kube config
gcloud container clusters get-credentials seagull
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
create_kubeconfig some_namespace

# use it!
for i in $(seq 1 10); do echo echo $i; done | monitor_experiment -k kubeconfig-some_namespace
```
