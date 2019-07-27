#!/usr/bin/env bash

GCE_REGION=$1

MULTIZONE=true ENABLE_ETCD_QUORUM_READ=true KUBE_GCE_ZONE="${GCE_REGION}-a" ./kubernetes/cluster/kube-up.sh

# Uncomment for HA deployment with multiple masters
#KUBE_GCE_ZONE="${GCE_REGION}-b" KUBE_REPLICATE_EXISTING_MASTER=true ./kubernetes/cluster/kube-up.sh

# Uncomment for HA deployment with multiple masters
#KUBE_GCE_ZONE="${GCE_REGION}-c" KUBE_REPLICATE_EXISTING_MASTER=true ./kubernetes/cluster/kube-up.sh
