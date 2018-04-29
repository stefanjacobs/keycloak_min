# KeyCloak Docker Image based on Alpine

Aim of this project is to create a very small Keycloak Docker installation in clustered mode with nothing but the admin account set up front.

## Environment variables

There are no Environment variables at the moment. In Docker File there are some envs, but admin user name and password should be resetted as soon as first instance is up.

It is to be expected that Database is configured by env-vars.

## File Description

Short description what is in which file.

### docker-compose.yml

Example of how to startup the image with above environmental variables.

### Dockerfile

The Dockerfile for the Image. From Alpine with Java install some apks and curl the keycloak image from official site. Copy the run.sh and the configuration and start up.

### run.sh

The startup script in the container. Nothing special here.

### standalone-ha.xml

HA Configuration. Only interesting is the JGroups configuration, e.g. [Discovery Protocols](http://www.jgroups.org/manual-3.x/html/protlist.html#DiscoveryProtocols).

## License

Creative Commons Attribution 4.0, see [License](./LICENSE).