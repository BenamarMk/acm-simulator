This document will detail the steps needed to deploy a wordpress application to simulate ACM interaction with Ramen.  The application consists of two Pods, mysql, and wordpress.  To simulate ACM interaction, we will need to create 3 directories.  Ramen directory will be used to contain Ramen CR.  The application directory will contain the resource yaml files for the app.  And the 3rd directory will be used by Ramen to backup the PVs to it.  It will simulate an object store bucket.

The steps are summarized in these steps:
1. Create the application resources
2. Deploy the application
3. Wait for the application until it is running
4. Simulate disaster
5. Restore the application in a different cluster

# Create the 3 directories
```
mkdir -p acm/ramen acm/app acm/pvbackups
```

# Deploy wordpress application
There are two steps involved in deploying an application: we need to create a ramen CR and the actual application resources.
Create a Ramen yaml file in acm/ramen directory
```
cat <<EOF >>acm/ramen/ramen.yaml 
# Ramen
kind: VolumeReplicationGroup
metadata:
    name: volume-replication-group
    Labels:
	  app: "wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75"
Spec:
    protocol: http/scp
    pvpath: <endpoint>
EOF
```

# Create or Copy application yaml files to acm/app/
For this example, the only thing that you need to change is the name of the storage class (if it is different from the one below).
Create mysql.yaml
```
cat <<EOF >>acm/app/mysql.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-pass
  labels:
    app: "wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75"
type: Opaque
data:
  password: dGhpc0lzSnVzdEFuRXhhbXBsZTIwMTkh
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql-hsvc
  labels:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
spec:
  ports:
    - port: 3306
  selector:
    app: "wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75"
  clusterIP: None
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
spec:
  selector:
    matchLabels:
      app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 

  replicas: 1
  serviceName: wordpress-mysql-hsvc
  template:
    metadata:
      labels:
        app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
    spec:
      containers:
      - image: mysql:5.6
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-persistent-storage
    spec:
      storageClassName: csi-rbd-sc 
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 2Gi
 
EOF
```

# Create wordpress.yaml
```
cat <<EOF >>acm/app/wordpress.yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress-webserver-svc
  labels:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
spec:
  ports:
    - port: 80
  selector:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
  clusterIP: None
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-webserver-hsvc
  labels:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
spec:
  ports:
    - port: 3306
  selector:
     app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75
  clusterIP: None
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: wordpress-webserver
  labels:
    app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
  annotations:
      kubernetes.io/application: wordpress
spec:
  replicas: 1
  serviceName: wordpress-webserver-hsvc
  selector:
    matchLabels:
      app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
  template:
    metadata:
      labels:
        app: wordpress-F9EBEE89-BD33-414B-85FE-4348A3949B75 
    spec:
      containers:
      - image: wordpress:4.8-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: wordpress-mysql-hsvc
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 80
          name: wordpress
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
  volumeClaimTemplates:
  - metadata:
     name: wordpress-persistent-storage
    spec:
      storageClassName: csi-rbd-sc 
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
 
EOF
```

# Export KUBECONFIG
```
export KUBECONFIG=/home/bmekhissi/acm/cluster-1/auth/kubeconfig
```

# Apply all yaml files in the following order
``` 
 kubectl apply -f acm/ramen
 kubectl apply -f acm/app
```

# SIMULATE DISASTER

Failover the application to Cluster2
```
export KUBECONFIG=/home/bmekhissi/acm/cluster-2/auth/kubeconfig
```

# Kubectl Apply all files in the order below
```
kubectl apply -f acm/ramen
kubectl apply -f acm/volumes
kubectl apply -f acm/app
```


