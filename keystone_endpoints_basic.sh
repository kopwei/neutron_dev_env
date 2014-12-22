#!/bin/sh
#
# Keystone basic Endpoints

# Mainly inspired by https://github.com/openstack/keystone/blob/master/tools/sample_data.sh

# Modified by Bilel Msekni / Institut Telecom
# Modified by Zhenfang Wei / Ericsson AB
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#

while getopts "H:d:u:D:p:m:K:R:E:T:vh" opt; do
  case $opt in
    H)
      KEYSTONE_HOST_IP=$OPTARG
      ;;
    K)
      MASTER=$OPTARG
      ;;
    R)
      KEYSTONE_REGION=$OPTARG
      ;;
    E)
      export SERVICE_ENDPOINT=$OPTARG
      ;;
    T)
      export SERVICE_TOKEN=$OPTARG
      ;;
    v)
      set -x
      ;;
    h)
      cat <<EOF
Usage: $0 -H keystone_host_ip [-D mysql_database]
       [-K keystone_master ] [ -R keystone_region ] [ -E keystone_endpoint_url ]
       [ -T keystone_token ]

Add -v for verbose mode, -h to display this message.
EOF
      exit 0
      ;;
    \?)
      echo "Unknown option -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done

# Host address
NEUTRON_HOST_IP=127.0.0.1

# Keystone definitions
KEYSTONE_REGION=RegionOne
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT="http://${KEYSTONE_HOST_IP}:35357/v2.0"


if [ -z "$KEYSTONE_REGION" ]; then
  echo "Keystone region not set. Please set with -R option or set KEYSTONE_REGION variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_TOKEN" ]; then
  echo "Keystone service token not set. Please set with -T option or set SERVICE_TOKEN variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_ENDPOINT" ]; then
  echo "Keystone service endpoint not set. Please set with -E option or set SERVICE_ENDPOINT variable." >&2
  missing_args="true"
fi

if [ -n "$missing_args" ]; then
  exit 1
fi

keystone service-create --name keystone --type identity --description 'OpenStack Identity'
keystone service-create --name neutron --type network --description 'OpenStack Networking service'

create_endpoint () {
  case $1 in
    identity)
    keystone endpoint-create --region $KEYSTONE_REGION --service_id $2 --publicurl 'http://'"$KEYSTONE_HOST_IP"':5000/v2.0' --adminurl 'http://'"$KEYSTONE_HOST_IP"':35357/v2.0' --internalurl 'http://'"$KEYSTONE_HOST_IP"':5000/v2.0'
    ;;
    network)
    keystone endpoint-create --region $KEYSTONE_REGION --service_id $2 --publicurl 'http://'"$NEUTRON_HOST_IP"':9696/' --adminurl 'http://'"$NEUTRON_HOST_IP"':9696/' --internalurl 'http://'"$NEUTRON_HOST_IP"':9696/'
    ;;
  esac
}

for i in identity network; do
    id=$(keystone service-list | grep $i | awk '{print $2}') || exit 1
    create_endpoint $i $id
done
