# A script that simulate ACM interaction with managed clusters.
## Clone Repository
```
https://github.com/BenamarMk/acm-simulator.git
```
## Basic Usage
```
acm-simulator.sh
```
This will deploy a sample application in the 'default' namespace. By default, the sample application is [wordpress](https://github.com/BenamarMk/acm-simulator/tree/main/examples/apps/wordpress). And in order for the wordpress application to be enabled for Disaster Recovery (DR), the default [ramen custom resource](https://github.com/BenamarMk/acm-simulator/tree/main/examples/ramen/wordpress) will also be used. And finally, the environment variable $KUBECONFIG is used to deploy the application on the managed cluster.

```
acm-simulator.sh --cluster-config /path/to/cluster/config  --namespace mynamespace --app /path/to/app --ramen /path/to/ramencr  
```
You can also specify non default arguments as shown.
* **--cluster-config:** the location of the config file for the cluster where the app will be deployed on
* **--namespace:** the namespace for the application
* **--app:** the path location of the app resources
* **--ramen:** is the path location of the ramen custom resource
```
acm-simulator.sh --pvpath /path/to/pv-backups
```
This command will deploy a wordpress application using the default app location, ramen cr, and cluster config.  The **--pvpath** is for deploying the backup up PVs during the failover/failback.

For more details, look at the full documentation [here](https://github.com/BenamarMk/acm-simulator/blob/main/docs/details.md)

