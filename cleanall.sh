#! /bin/sh

docker rm -f $(docker ps -qa)
docker rmi alpine:git-server
