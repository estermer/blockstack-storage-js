#!/bin/sh

BLOCKSTACK_BRANCH="master"
BLOCKSTACK_JS_BRANCH="develop-jude"

# get bitcoind
sudo add-apt-repository -y ppa:bitcoin/bitcoin || exit 1
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys F76221572C52609D
sudo apt-get -y update || exit 1
sudo apt-get -y install bitcoind || exit 1

# needed on CircleCI's VMs
pip install --upgrade pip
pip install --upgrade six
pip install --upgrade setuptools
pip install --upgrade cryptography
pip install --upgrade scrypt
pip install --upgrade fastecdsa

# fetch and install virtualchain 
git clone https://github.com/blockstack/virtualchain /tmp/virtualchain
cd /tmp/virtualchain && git checkout "$BLOCKSTACK_BRANCH"
cd /tmp/virtualchain && ./setup.py build && ./setup.py install

# fetch blockstack core and integration tests
git clone https://github.com/blockstack/blockstack-core /tmp/blockstack-core
cd /tmp/blockstack-core && git checkout "$BLOCKSTACK_BRANCH"

# install blockstack core and integration tests
cd /tmp/blockstack-core && ./setup.py build && ./setup.py install 
cd /tmp/blockstack-core/integration_tests && ./setup.py build && ./setup.py install

# set up node
npm install -g babel
npm install -g browserify
sudo mkdir -p /usr/lib/node_modules

# get blockstack.js 
git clone https://github.com/blockstack/blockstack.js /tmp/blockstack.js
cd /tmp/blockstack.js && git checkout "$BLOCKSTACK_JS_BRANCH" && npm install 

exit 1

# keep the integration test framework happy
sudo rm -rf /usr/lib/node_modules/blockstack
sudo cp -a /tmp/blockstack.js /usr/lib/node_modules/blockstack

# keep the integration test framework happy
sudo rm -rf /usr/lib/node_modules/blockstack-storage
sudo cp -a /tmp/blockstack-storage.js /usr/lib/node_modules/blockstack-storage

# run the relevant integration tests
blockstack-test-scenario blockstack_integration_tests.scenarios.name_preorder_register_portal_auth || exit 1

# keep the integration test framework happy
sudo rm -rf /usr/lib/node_modules/blockstack
sudo cp -a /tmp/blockstack.js /usr/lib/node_modules/blockstack
sudo rm -rf /usr/lib/node_modules/blockstack-storage
sudo cp -a /tmp/blockstack-storage.js /usr/lib/node_modules/blockstack-storage

blockstack-test-scenario blockstack_integration_tests.scenarios.name_preorder_register_portal_datastore || exit 1
