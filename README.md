# A script that simulate ACM interaction with managed clusters.
## Basic Usage
```
acm-simulator.sh
```
This will deploy a sample application in 'default' namespace. The sample application is [wordpress](https://github.com/BenamarMk/acm-simulator/tree/main/examples/apps/wordpress).
By default, the environment variable $KUBECONFIG is used to deploy the application on the managed cluster.

```
acm-simulator.sh --cluster-config /path/to/cluster/config  --namespace mynamespace --app /path/to/app --ramen /path/to/ramencr  
```
You can also run acm-simulator with non default arguments.
--cluster-config: the location of the config file for the cluster where the app will be deployed on
--namespace: the namespace for the application
--app: the path location of the app resources
--ramen: is the path location of the ramen custom resource
```
acm-simulator.sh --pvpath
```
This command will deploy a wordpress application usging the default app location, ramencr, and cluster config.  The --pvpath is used for deploying the backup PVs during the failover/failback.

