#!/bin/bash

command -v keystone >/dev/null 2>&1 ||\
    { echo >&2 "keystone client program but it's not installed.  Aborting."; exit 1; }

echo "Stopping existing containers"
# Stop and clear the existing containers
for i in "mysql" "garland/docker-openstack-keystone" "dockerfile/rabbitmq"; do
    container_id=$(docker ps | grep $i | awk {'print $1'})
    if [ -n $container_id ];then
        echo "Stopping ${i}"
        docker stop $container_id
        docker rm $container_id
    fi
done

echo "Starting mysql"
docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=neutron -d mysql
echo "Starting keystone"
docker run -p 35357:35357 -p 5000:5000 -d garland/docker-openstack-keystone
echo "Starting rabbitmq"
docker run -p 5672:5672 -p 15672:15672 -d dockerfile/rabbitmq

sh keystone_basic.sh
sh keystone_endpoint_basic.sh


