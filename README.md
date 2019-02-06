# docker-kimai installation

A simple apache installation with all required modules to run kimai. Let's encrypt can be used to optain a valid certificate. 
  
## Configuration
 
### Configuration files, log files, buisness data
The following directories can be loaded from the host to keep the data and configuration files out of the container:

 | PATH in container | Description |
 | ---------------------- | ----------- |
 | /var/log/apache2 | Logging directory |
 | /etc/letsencrypt | Storage of the created let's encrypt certificates. If this directory is empty on start a default configuration is provided.|
 | /var/www/html/includes | Configuration directroy for kimai |
 
### Environment variables
The following environment variables are available to configure the container on startup.

 | Environment Variable | Description |
 | ---------------------- | ----------- |
 | LETSENCRYPTDOMAINS | Comma seperated list of all domainnames to request/renew a let's encrypt certificate |
 | LETSENCRYPTEMAIL | E-Mail to be used for notifications from let's encrypt |

## Container Tags

 | Tag name | Description |
 | ---------------------- | ----------- |
 | latest | Latest stable version of the container |
 | stable | Latest stable version of the container |
 | dev | latest development version of the container. Do not use in production environments! |

## Usage

To run the container and store the data and configuration on the local host run the following commands:
1. Create storage directroy for the configuration files, log files and data. Also create a directroy to store the necessary script to create the docker container and replace it (if not using eg. watchtower)
```
mkdir /srv/docker/kimai
mkdir /srv/docker-config/kimai
```

2. Create an file to store the configuration of the environment variables
```
touch /srv/docker-config/kimai/env_file
``` 
```
#Comma seperated list of domainnames
LETSENCRYPTDOMAINS=kimai.example.com
LETSENCRYPTEMAIL=example@example.com
```

3. Create the docker container and configure the docker networks for the container. I always create a script for that and store it under
```
touch /srv/docker-config/kimai/create.sh
```
Content of create.sh:
```
#!/bin/bash

docker pull foxcris/docker-kimai
docker create\
 --restart always\
 --name kimai\
 --volume "/srv/docker/kimai/var/www/html/includes:/var/www/html/includes"\
 --volume "/srv/docker/kimai/var/log/apache2:/var/log/apache2"\
 --volume "/srv/docker/kimai/etc/letsencrypt:/etc/letsencrypt"\
 --env-file=/srv/docker-config/kimai/env_file\
 -p 80:80\
 -p 443:443\
 foxcris/docker-kimai
docker network connect database-net kimai
```

4. Create replace.sh to install/update the container. Store it in
```
touch /srv/docker-config/kimai/replace.sh
```
```
#/bin/bash
docker stop kimai
docker rm kimai
./create.sh
docker start kimai
```

 
### Database
For a database you can use the standard mariadb docker container and connect it via a docker network.

### Update of kimai
After an update you have to enter the url:
http://example.example.com/updater/updater.php

### Security - availablity of the installer of kimai
The installer of kimai is only available as long as the configuration has not be stored by kimai. On each start it is checked if the _autoconf.php_ file in _/var/www/html/includes_ extists. This file is created from the installer of kimai. If this file exits the installer directory is deleted.
