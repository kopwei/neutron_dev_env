#!/bin/bash

command -v keystone >/dev/null 2>&1 ||\
    { echo >&2 "keystone client program but it's not installed.  Aborting."; exit 1; }

if [ "$(uname)" == "Darwin" ]; then
    if [ -z $DOCKER_HOST ]; then
        echo >&2 "Docker host is not set, did you started boot2docker?"
        exit 1
    fi
fi

echo "Stopping existing containers"
echo
# Stop and clear the existing containers
for i in "mysql" "garland/docker-openstack-keystone" "dockerfile/rabbitmq"; do
    container_id=$(docker ps | grep $i | awk {'print $1'})
    if [ -z $container_id ];then
        :
    else
        echo "Stopping ${i}"
        docker stop $container_id > /dev/null 2>&1
        docker rm $container_id > /dev/null 2>&1
    fi
done

echo
echo "Starting containers"
echo
echo "Starting mysql"
docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=neutron -d mysql > /dev/null 2>&1
echo "Starting keystone"
docker run -p 35357:35357 -p 5000:5000 -d garland/docker-openstack-keystone > /dev/null 2>&1
echo "Starting rabbitmq"
docker run -p 5672:5672 -p 15672:15672 -d dockerfile/rabbitmq > /dev/null 2>&1

sleep 10

source openrc
echo "Preparing keystone tenants and endpoints... "
if [ "$(uname)" == "Darwin" ]; then
   docker_ip=$(boot2docker ip)
   sh keystone_basic.sh ${docker_ip} > /dev/null 2>&1
   sh keystone_endpoints_basic.sh -H ${docker_ip} > /dev/null 2>&1
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    sh keystone_basic.sh "127.0.0.1" > /dev/null 2>&1
    sh keystone_endpoints_basic.sh -H "127.0.0.1" > /dev/null 2>&1
fi

echo "The neutron dev environment is configured, feel free to start neutron server"

