#!/bin/bash

# kch = keycloak home
KCH=/keycloak

function is_keycloak_running {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${KEYCLOAK_PORT}/auth/admin/realms)
    if [[ $http_code -eq 401 ]]; then
        return 0
    else
        return 1
    fi
}

function configure_keycloak {
    until is_keycloak_running; do
        echo Keycloak still not running, waiting 5 seconds
        sleep 5
    done

    echo Keycloak is running, proceeding with configuration

    ${KCH}/bin/kcadm.sh config credentials --server http://localhost:${KEYCLOAK_PORT}/auth --user $KEYCLOAK_ADMIN_USER --password $KEYCLOAK_ADMIN_PASSWORD --realm master

    if [ $KEYCLOAK_REALM ]; then
        echo Creating realm $KEYCLOAK_REALM
        ${KCH}/bin/kcadm.sh create realms -s realm=$KEYCLOAK_REALM -s enabled=true
    fi

    if [ "$KEYCLOAK_CLIENT_IDS" ]; then
        for client in ${KEYCLOAK_CLIENT_IDS//,/ }; do 
            echo Creating client $client
            echo '{"clientId": "'${client}'", "webOrigins": ["'${KEYCLOAK_CLIENT_WEB_ORIGINS}'"], "redirectUris": ["'${KEYCLOAK_CLIENT_REDIRECT_URIS}'"]}' | ${KCH}/bin/kcadm.sh create clients -r ${KEYCLOAK_REALM:-master} -f -
        done
    fi

    if [ "$KEYCLOAK_REALM_ROLES" ]; then
        for role in ${KEYCLOAK_REALM_ROLES//,/ }; do
            echo Creating role $role
            ${KCH}/bin/kcadm.sh create roles -r ${KEYCLOAK_REALM:-master} -s name=${role}
        done
    fi
    
    if [ "$KEYCLOAK_REALM_SETTINGS" ]; then
        echo Applying extra Realm settings
        echo $KEYCLOAK_REALM_SETTINGS | ${KCH}/bin/kcadm.sh update realms/${KEYCLOAK_REALM:-master} -f -
    fi

    if [ $KEYCLOAK_USER_USERNAME ]; then
        echo Creating user $KEYCLOAK_USER_USERNAME
        # grep would have been nice instead of the double sed, but we don't have gnu grep available, only the busybox grep which is very limited
        local user_id=$(echo '{"username": "'$KEYCLOAK_USER_USERNAME'", "enabled": true}' \
                            | ${KCH}/bin/kcadm.sh create users -r ${KEYCLOAK_REALM:-master} -f - 2>&1  | sed -e 's/Created new user with id //g' -e "s/'//g")
        echo "Created user with id ${user_id}"
        ${KCH}/bin/kcadm.sh update users/${user_id}/reset-password -r ${KEYCLOAK_REALM:-master} -s type=password -s value=${KEYCLOAK_USER_PASSWORD} -s temporary=false -n
        echo "Set password for user ${user_id}"
        if [ $KEYCLOAK_USER_ROLES ]; then
            ${KCH}/bin/kcadm.sh add-roles --uusername ${KEYCLOAK_USER_USERNAME} --rolename ${KEYCLOAK_USER_ROLES//,/ --rolename } -r ${KEYCLOAK_REALM:-master}
	    echo Added roles ${KEYCLOAK_USER_ROLES//,/ }
        fi
    fi

}

if [ ! -f /keycloak/standalone/data/docker-container-configuration-done ]; then
    touch /keycloak/standalone/data/docker-container-configuration-done
    configure_keycloak &
fi

# this is not in a volume, at least not by default, so we need to replace the port every time the server runs
sed -i -e 's/<socket-binding name="http".*/<socket-binding name="http" port="'$KEYCLOAK_PORT'"\/>/' ${KCH}/standalone/configuration/standalone.xml

${KCH}/bin/add-user-keycloak.sh --user $KEYCLOAK_ADMIN_USER --password $KEYCLOAK_ADMIN_PASSWORD

${KCH}/bin/standalone.sh --server-config=standalone-ha.xml -b 0.0.0.0
