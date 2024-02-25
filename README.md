# Using Raspberry Pi + Docker for Home Assistant Work
- note #1 we will be accessing the Raspberry Pi from a client laptop/computer to publish and maintain any docker images you deploy.  Docker will be running on the Pi but you will also want docker on the client so that you have all the docker commands available
  - [Installing Docker Desktop on Mac or Windows](https://www.docker.com/products/docker-desktop/)
- note #2 you will want to create an image of your Pi SD card after everything is working so you have a clean backup in case you need to start over.
- note #3 This tutorial assumes you have some knowledge of Raspberry Pi, Linux command line, and Visual Studio Code
- My client machine was a Mac so many of commands such as SSH and ssh-keygen were already innstalled
- note #4 the following values are used:
    - Raspnerry Pi host name: homeauto1
    - key file name: homeauto1
    - user name: larry

## Basic Raspberry Pi Setup
* [Download Raspberry Pi OS Lite](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit)
* [Download Rasbperry Pi Imager](https://www.raspberrypi.com/software/)
* [Customize Raspberry Pi image](https://www.clustered-pi.com/blog/raspberry-pi-imager-secret-menu.html)
  *  Set host name
  *  Enable SSH
     *  Use Password authentication (you will set up SSH login with keys later)
     *  Configure WiFi
     *  Set time zone
  
* [Set up SSH with key](https://www.geekyhacker.com/configure-ssh-key-based-authentication-on-raspberry-pi/)
  
    * on the client machine enter:
    ``` console
    $ ssh-keygen -t rsa
    ```
    * Enter path and file name to save the key - usually: ~/.ssh/homeauto1
    * Select empty passphrase (note - because I haven't figured out how to use a passphrase with Docker context I've opted to leave this out and leave a blank passphrase - consider the security risks when doing this)
    * When finished, you should have two files in ~/.ssh one with the file name you have and another with the file name and a .pub extension.  In this case I used a file name of homeauto1:
        * Note: it is important to set the permissions of the new key files as such:

        ``` console
        $ chmod 600 ~/.ssh/homeauto1
        $ chmod 600 ~/.ssh/homeauto1.pub
        ```

    <img src="./docs/images/keys.png" width="500px" alt=".ssh directory listing" />

    * Copy the public key to the Raspberry Pi:
  
    ``` console
    $ ssh-copy-id -i ~/.ssh/homeauto1.pub \larry@homeauto1
    ```

    * Edit client file sshd_config on the Raspberry Pi and change the following lines:

    ``` console
    PermitRootLogin no
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    UsePAM no
    X11Forwarding no
    ```
    * Restart the SSH service:
  
    ``` console
    $ sudo systemctl reload sshd
    ```

    * On your client machine, edit the file ~/.ssh/config and add the following lines to the bottom of the file:
      * Note: it is important to use the private key (file without the .pub file extension) on the IdentityFile attribute:
  
    ```console
    Host homeauto1
        Hostname homeauto1
        User larry
        IdentityFile ~/.ssh/homeauto1
        ControlMaster auto
        ControlPath ~/.ssh/control-%C
        ControlPersist yes
        Port 22
    ```

    * You can now ssh into the Raspberry Pi with the new key and no password required
  
    ``` console
    $ ssh larry@homeauto1
    ```
* [Install Docker on the Raspberry Pi](https://docs.docker.com/engine/install/raspberry-pi-os/)
  * Note: I recommend choosing the "Install using the apt repository" method documented here
  * Note: On a clean/new Raspberry Pi OS install there should be no Docker installation present
  * Note: [How to Completely Uninstall Docker](https://www.benjaminrancourt.ca/how-to-completely-uninstall-docker/)
* [Configure remote access for Docker daemon](https://docs.docker.com/config/daemon/remote-access/)
  * Note: I recommend following the method "Configuring remote access with systemd unit file"
  * On the Raspberry Pi, add or edit the following:
    ```console
    $ sudo systemctl edit docker.service
    ```
    ```console
    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
    ```
    Reload the systemctl configuration:
    ```console
    $ sudo systemctl daemon-reload
    ```
    Restart Docker:
    ```console
    $ sudo systemctl restart docker.service
    ```
    Verify the change:

    ``` console
    $ sudo netstat -lntp | grep dockerd

    tcp        0      0 127.0.0.1:2375          0.0.0.0:*               LISTEN      3758/dockerd
    ```


* On the Raspnerry Pi, add your user account to the docker group:
  * Create docker group:
    ```console
    $ sudo groupadd docker
    ```
  * Add current logged in user to group:
    ```console
    $ sudo usermod -aG docker $USER
    ```

* [Working on remote Docker Host using docker context](https://gist.github.com/dnaprawa/d3cfd6e444891c84846e099157fd51ef#docker-context-setup)
  * Note: Since you've already setup remote SSH, you can skip to the section "Docker Context setup"
  * On your client, issue the followig commands:
  * Note: when you specify the ssh URL below, I had to omit the user@ and just put ssh://homeauto1
  
    ``` console
    $ docker context create raspberrypi --docker "host=ssh://homeauto1"
    ```
    And switch to the new context:
    ``` console
    $ docker context use raspberrypi
    ```
    Test remote command
    ``` console
    $ docker ps

    CONTAINER ID   IMAGE              COMMAND                  CREATED       STATUS       PORTS
    ```

* Test docker by building a simple web app:
    * https://stackoverflow.com/questions/66430098/basic-nginx-container-static-file

    * Create a folder to hold some code
    * In the folder, create the following two files:

        Dockerfile:
        ```
        FROM nginx:1.18.0

        WORKDIR /usr/share/nginx/html
        COPY index.html ./
        ```

    * index.html:

        ``` html
        <!DOCTYPE html>
        <html>
            <head>
                <title>Testing</title>
            </head>
            <body>
                <p>Hello Test App</p>
            </body>
        </html>
        ```


    * Enter the following at the command prompt:
        ``` console
        $ docker image build --tag nginx-test:1.0.0 --file ./Dockerfile .
        ```

        ``` console
        $ docker run -d -p 3737:80 nginx-test:1.0.0
        ```

        ``` console
        $ curl http://localhost:3737

        <!DOCTYPE html>
        <html>
            <head>
                <title>Testing</title>
            </head>
            <body>
                <p>Hello Test App</p>
            </body>
        </html>
        ```

    * You should see the HTML contents of index.html displayed

    * Stop container:
        ``` console
        $ docker container stop <container id>
        ```
    