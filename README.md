Edit Dockerfile and set PASSWORD:

    PASSWORD=supersecret


Build the docker image:

    $ docker build -t alpine:git-server -f Dockerfile .


Copy your public key:

    $ cp key.pub /home/<username>/git/keys/


Run the container:

    $ docker run -d -ti --name <container-name> -p 2222:22 -v /home/<username>/git/repos/:/git-server/repos -v /home/<username>/git/keys/:/git-server/keys alpine:git-server

where:

    - /git-server/repos is a volume to store repositories
    - /git-server/keys is a volume to store the user public keys


After any change:

    $ docker restart <container-name>


Test it works:

    $ ssh git@<server-running-docker> -p 2222


Create a new repo:

    cd /home/<username>/git/repos/
    mkdir -p <repo-name>
    cd <repo-name>
    git --bare init


Pull an existing repo:

    $ cd <repo-name>
    $ git remote add <remote-name> git@<server-running-docker>:/git-server/repos/<repo-name>
    $ git push <remote-name> <remote-branch>


Clone repo:

    $ git clone git@<server-running-docker>:/git-server/repos/<repo-name>



Stop the container:

    $ docker stop <container-name>
    $ docker rm -f <container-name>




