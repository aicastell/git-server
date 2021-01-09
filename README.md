

Clone the repo:

    $ cd /home/<username>
    $ git clone https://github.com/aicastell/git-server.git


Create directories keys and repos

    $ cd git-server
    $ mkdir -p keys repos
    

Edit Dockerfile and set PASSWORD:

    PASSWORD=supersecret


Build the docker image:

    $ docker build -t alpine:git-server -f Dockerfile .


Copy your public key:

    $ cp /path/to/key.pub /home/<username>/git-server/keys/


Run the container:

    $ docker run -d -ti --name <container-name> -p 2222:22 -v /home/<username>/git-server/repos/:/git-server/repos -v /home/<username>/git-server/keys/:/git-server/keys alpine:git-server

where:

    - /home/<username>/git-server/repos is a volume to store repositories
    - /home/<username>/git-server/keys is a volume to store the user public keys


After any change:

    $ docker restart <container-name>


Test it works:

    $ ssh git@<server-running-docker> -p 2222


Create a new repo (in server-running-docker):

    cd /home/<username>/git-server/repos/
    mkdir -p <repo-name>
    cd <repo-name>
    git --bare init



Setup connections to remote server vía 2222 port:

    $ cat /etc/hosts
    192.168.1.xx 	<server-running-docker>

    $ cat ~/.ssh/config
    Host <server-running-docker>
        Port 2222

    

Pull an existing repo (in your local PC):

    $ cd <repo-name>
    $ git remote add <remote-name> git@<server-running-docker>:/git-server/repos/<repo-name>
    $ git push <remote-name> <remote-branch>


Clone repo:

    $ git clone git@<server-running-docker>:/git-server/repos/<repo-name>



Stop the container:

    $ docker stop <container-name>
    $ docker rm -f <container-name>


