#!/usr/bin/env bash

MULTIZONE=true ENABLE_ETCD_QUORUM_READ=true KUBE_GCE_ZONE=asia-southeast1-a ./kubernetes/cluster/kube-up.sh

#KUBE_GCE_ZONE=asia-southeast1-b KUBE_REPLICATE_EXISTING_MASTER=true ./kubernetes/cluster/kube-up.sh

#KUBE_GCE_ZONE=asia-southeast1-c KUBE_REPLICATE_EXISTING_MASTER=true ./kubernetes/cluster/kube-up.sh
