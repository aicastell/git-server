#! /bin/sh

docker build -t alpine:git-server -f Dockerfile .
docker run -d -ti --name git -p 2222:22 -v /home/aicastell/git/repos/:/git-server/repos -v /home/aicastell/git/keys/:/git-server/keys alpine:git-server

# in case you need to enter into the container
# docker exec -ti git sh


