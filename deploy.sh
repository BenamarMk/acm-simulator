#!/bin/bash

# UNCOMMENT this line to enable debugging
# set -xv
NAMESPACE='default'
CLUSTERCONFIG=$KUBECONFIG
APP='./examples/apps/wordpress'
PVPATH=$APP
RAMEN='./examples/ramen/wordpress'

errorExit () {
    echo -e "\nERROR: $1\n"
    exit 1
}

usage () {
    cat << END_USAGE
${SCRIPT_NAME} - Deploy a sample application to the specified cluster
Usage: ${SCRIPT_NAME} <options>
-n | --namespace <name>                : Namespace to analyse.                   Default: default
-c | --cluster-config <path>           : Config file of the cluster.             Default: KUBECONFIG
-r | --ramen <path>                    : Directory to the Ramen CR yaml file     Default: RAMEN path
-a | --app <path>                      : Directory to the yaml files to deploy.  Default: APP path
-p | --pvpath <path>                   : Backup PVs location.                    Default: same as the app location
-h | --help                            : Show this usage
Examples:
========
Deploy an appplication to a cluster with defaults:$ ${SCRIPT_NAME}
Deploy an application to a cluster without defaults: $ ${SCRIPT_NAME} --namespace bar --cluster-confi path/to/kubeconfig --ramen path/to/ramencr --app path/to/appcr --pvpath path/to/backedupPVs
END_USAGE

    exit 1
}

# Process command line options. See usage above for supported options
processOptions () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --namespace)
                NAMESPACE="$2"
                shift 2
            ;;
            -c | --cluster-config)
                CLUSTERCONFIG="$2"
                shift 2
            ;;
            -p | --app)
                APP="$2"
                shift 2
            ;;
            -p | --pvpath)
                PVPATH="$2"
                shift 2
            ;;
            -h | --help)
                usage
                exit 0
            ;;
            *)
                usage
            ;;
        esac
    done

    [ -z "${CLUSTERCONFIG}" ] && errorExit "ENV KUBECONFIG must be set or use --cluster-config 'path/to/kubeconfig')"
    export KUBECONFIG=$CLUSTERCONFIG
}

# Test connection to a cluster by kubectl
deploy () {
    local i=1
    echo "$i. Create $NAMESPACE namespace if does not exist"
    kubectl create namespace $NAMESPACE > /dev/null 2>&1

    let "i++"
    echo "$i. Create ramen custom resource -- location $RAMEN"
    kubectl apply -f $RAMEN -n $NAMESPACE

    if [ "$APP" != "$PVPATH" ]; then
        let "i++"
        echo "$i. Create backed up PVs -- location $PVPATH"
        kubectl apply -f $PVPATH -n $NAMESPACE
    fi
    
    let "i++"
    echo "$i. Create the application resources -- location $APP"
    kubectl apply -f $APP -n $NAMESPACE

    let "i++"
    echo "$i. Watch for deployed PODs"
    watch kubectl get pods -n $NAMESPACE
}

main () {
    processOptions "$@"
    deploy "$@"
}

######### Main #########

main "$@"

