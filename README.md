This document explains:

    1. Steps to configure the server running docker
    2. Steps to configure git client
    3. All in one step


1. Steps to configure the server running docker:

In the server running docker you have to:

    1) Clone this repo:

        $ cd /home/<username>
        $ git clone https://github.com/aicastell/git-server.git


    2) Create directories keys and repos

        $ cd git-server
        $ mkdir -p keys repos
        

    3) Edit Dockerfile and set PASSWORD:

        PASSWORD=supersecret


    4) Build the docker image:

        $ docker build -t alpine:git-server -f Dockerfile .


    5) Copy your public key:

        $ cp /path/to/key.pub /home/<username>/git-server/keys/


    6) Run the container:

        $ docker run -d -ti --name <container-name> \
            -p 2222:22 \
            -v /home/<username>/git-server/repos/:/git-server/repos \
            -v /home/<username>/git-server/keys/:/git-server/keys \
            alpine:git-server

    where:

        - /home/<username>/git-server/repos is a volume to store repositories
        - /home/<username>/git-server/keys is a volume to store the user public keys


    7) Every time you need to create a new repo, you have to do this:

        $ cd /home/<username>/git-server/repos/
        $ mkdir -p <repo-name>
        $ cd <repo-name>
        $ git --bare init

    An then:

        $ docker restart <container-name>


    8) If you need to stop the container:

        $ docker stop <container-name>
        $ docker rm -f <container-name>



2. Steps to configure git client

In your local PC you have to:

    1) Check if docker server is properly running:

        $ ssh git@<server-running-docker> -p 2222



    2) Setup server name and IP:

        $ cat /etc/hosts
        192.168.1.xx 	<server-running-docker>



    3) Setup connections to remote server vía 2222 port:

        $ cat ~/.ssh/config
        Host <server-running-docker>
            Port 2222

        
    4) Push an existing git repository to your dockerized server:

        $ cd <repo-name>
        $ git remote add <remote-name> git@<server-running-docker>:/git-server/repos/<repo-name>
        $ git push <remote-name> <remote-branch>


    5) Clone remote repo into local directory:

        $ git clone git@<server-running-docker>:/git-server/repos/<repo-name>



3. All in one

You can do all steps easily using docker-compose:

    1) Install docker-compose:

        $ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose


    2) Edit docker-compose.yml and set the <USER> properly


    3) Build the image:

        $ docker-compose build


    4) Start the container:

        $ docker-compose up -d


    5) Stop the container:

        $ docker-compose down


Hope this helps! :)


