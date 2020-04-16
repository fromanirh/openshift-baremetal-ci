#!/bin/bash

set -e
set -x

trap cleanup 0 1

cleanup() {
	oc get co || true
	oc get clusterversion || true
	oc get nodes || true
	oc get pods -n openshift-ptp || true
	oc get pods -n default || true
	./cleanup.sh || true
	popd
}

pushd openshift-baremetal-ci/tests/ptp
./run-ptp-operator.sh

# wait for extra 20 seconds
sleep 20
popd

if [ -d ptp-operator ]; then
        rm -rf ptp-operator
fi

git clone https://github.com/openshift/ptp-operator.git

pushd ptp-operator

# skip test that fails on CI servers due to NIC issue
sed -i -e 's/^GOFLAGS=.*//g' hack/run-functests.sh
echo "GOFLAGS=-mod=vendor ginkgo --skip 'Slave can sync to master' ./test -- -junit \$JUNIT_OUTPUT" >> hack/run-functests.sh

make functests

popd
pushd openshift-baremetal-ci/tests/ptp/ptp-operator
make undeploy
