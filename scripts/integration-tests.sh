#!/bin/bash
set -e

KUBECTL_VERSION=${KUBECTL_VERSION:?}
KUBECFG_VERSION=${KUBECFG_VERSION:?}
KSONNET_VERSION=${KSONNET_VERSION:?}

install_kubectl() {
    which kubectl || {
        curl -fLsSO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
        sudo install kubectl /usr/local/bin/
    }
}

install_minikube() {
    `dirname $0`/install-minikube.sh
}

install_kubecfg() {
    which kubecfg || {
        curl -fLsS -o kubecfg https://github.com/ksonnet/kubecfg/releases/download/${KUBECFG_VERSION}/kubecfg-linux-amd64
        sudo install kubecfg /usr/local/bin/
    }

    if [ ! -d "ksonnet-lib" ]; then
        git clone --branch=${KSONNET_VERSION} --depth=1 https://github.com/ksonnet/ksonnet-lib.git ksonnet-lib
    fi
    export KUBECFG_JPATH=$PWD/ksonnet-lib
}

install_kubeless() {
    kubectl create ns kubeless
    kubectl create -f https://github.com/kubeless/kubeless/releases/download/$KUBELESS_VERSION/kubeless-$KUBELESS_VERSION.yaml
    kubectl create -f https://github.com/kubeless/kafka-trigger/releases/download/$KUBELESS_KAFKA_VERSION/kafka-zookeeper-$KUBELESS_KAFKA_VERSION.yaml
    curl -LO https://github.com/kubeless/kubeless/releases/download/$KUBELESS_VERSION/kubeless_linux-amd64.zip
    unzip kubeless_linux-amd64.zip
    sudo mv ./bundles/kubeless_linux-amd64/kubeless /usr/local/bin/kubeless
    until kubectl get pods -l kubeless=kafka -n kubeless | grep Running; do
        echo -n ".";
        sleep 5;
    done
}

install_minio() {
    kubectl create -f `dirname $0`/../test/minio.yml
    until kubectl get pods -l app=minio -n kubeless | grep Running; do
        echo -n ".";
        sleep 5;
    done
}

# Install dependencies
echo "Installing kubectl"
install_kubectl
echo "Installing Minikube"
install_minikube
echo "Installing kubecfg"
install_kubecfg
echo "Installing Kubeless"
install_kubeless
echo "Installing Minio"
install_minio
kubectl get all --all-namespaces

# Run tests
set +e
npm run examples
result=$?
set -e

# Clean up
minikube delete

exit $result
