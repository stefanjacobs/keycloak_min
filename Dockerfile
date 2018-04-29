FROM openjdk:8-jdk-alpine

MAINTAINER stefan_j@gmx.de

ENV KEYCLOAK_VERSION 3.4.3.Final
ENV KEYCLOAK_PORT=8080
ENV KEYCLOAK_ADMIN_USER=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin

RUN apk update && apk add tar gzip curl bash && \
    curl https://downloads.jboss.org/keycloak/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.tar.gz | tar xzvf - && \
    mv keycloak-${KEYCLOAK_VERSION} keycloak && apk del tar gzip

VOLUME /keycloak/standalone/data

COPY run.sh /
COPY standalone-ha.xml /keycloak/standalone/configuration/

CMD bash /run.sh
