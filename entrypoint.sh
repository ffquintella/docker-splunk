#!/bin/bash

set -e
 
chown -R splunk:splunk /opt/splunk

if [ "$1" = 'splunk' ]; then
  shift
  sudo -HEu ${SPLUNK_USER} ${SPLUNK_HOME}/bin/splunk "$@"
elif [ "$1" = 'start-service' ]; then
  # If user changed SPLUNK_USER to root we want to change permission for SPLUNK_HOME
  if [[ "${SPLUNK_USER}:${SPLUNK_GROUP}" != "$(stat --format %U:%G ${SPLUNK_HOME})" ]]; then
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}
  fi

  # If version file exists already - this Splunk has been configured before
  __configured=false
  if [[ -f ${SPLUNK_HOME}/etc/splunk.version ]]; then
    __configured=true
  fi

  # If these files are different override etc folder (possible that this is upgrade or first start cases)
  # Also override ownership of these files to splunk:splunk
  if ! $(cmp --silent /var/opt/splunk/etc/splunk.version ${SPLUNK_HOME}/etc/splunk.version); then
    cp -fR /var/opt/splunk/etc ${SPLUNK_HOME}
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/etc
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/var
  fi

  sudo -HEu ${SPLUNK_USER} ${SPLUNK_HOME}/bin/splunk start --accept-license --answer-yes --no-prompt
  trap "sudo -HEu ${SPLUNK_USER} ${SPLUNK_HOME}/bin/splunk stop" SIGINT SIGTERM EXIT

  # If this is first time we start this splunk instance
  if [[ $__configured == "false" ]]; then
    __restart_required=false

    # Setup deployment server
    if [[ ${SPLUNK_ENABLE_DEPLOY_SERVER} == "true" ]]; then
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk enable deploy-server -auth admin:changeme"
      __restart_required=true
    fi

    # Setup deployment client
    # http://docs.splunk.com/Documentation/Splunk/latest/Updating/Configuredeploymentclients
    if [[ -n ${SPLUNK_DEPLOYMENT_SERVER} ]]; then
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk set deploy-poll ${SPLUNK_DEPLOYMENT_SERVER} -auth admin:changeme"
      __restart_required=true
    fi

    if [[ "$__restart_required" == "true" ]]; then
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk restart"
    fi

    # Setup listening
    # http://docs.splunk.com/Documentation/Splunk/latest/Forwarding/Enableareceiver
    if [[ -n ${SPLUNK_ENABLE_LISTEN} ]]; then
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk enable listen ${SPLUNK_ENABLE_LISTEN} -auth admin:changeme ${SPLUNK_ENABLE_LISTEN_ARGS}"
    fi

    # Setup forwarding server
    # http://docs.splunk.com/Documentation/Splunk/latest/Forwarding/Deployanixdfmanually
    if [[ -n ${SPLUNK_FORWARD_SERVER} ]]; then
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add forward-server ${SPLUNK_FORWARD_SERVER} -auth admin:changeme ${SPLUNK_FORWARD_SERVER_ARGS}"
    fi
    for n in {1..10}; do
      if [[ -n $(eval echo \$\{SPLUNK_FORWARD_SERVER_${n}\}) ]]; then
        sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add forward-server $(eval echo \$\{SPLUNK_FORWARD_SERVER_${n}\}) -auth admin:changeme $(eval echo \$\{SPLUNK_FORWARD_SERVER_${n}_ARGS\})"
      else
        # We do not want to iterate all, if one in the sequence is not set
        break
      fi
    done

    # Setup monitoring
    # http://docs.splunk.com/Documentation/Splunk/latest/Data/MonitorfilesanddirectoriesusingtheCLI
    # http://docs.splunk.com/Documentation/Splunk/latest/Data/Monitornetworkports
    if [[ -n ${SPLUNK_ADD} ]]; then
        sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add ${SPLUNK_ADD} -auth admin:changeme"
    fi
    for n in {1..30}; do
      if [[ -n $(eval echo \$\{SPLUNK_ADD_${n}\}) ]]; then
        sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add $(eval echo \$\{SPLUNK_ADD_${n}\}) -auth admin:changeme"
      else
        # We do not want to iterate all, if one in the sequence is not set
        break
      fi
    done

    # Execute anything
    if [[ -n ${SPLUNK_CMD} ]]; then
        sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk ${SPLUNK_CMD}"
    fi
    for n in {1..30}; do
      if [[ -n $(eval echo \$\{SPLUNK_CMD_${n}\}) ]]; then
        sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk $(eval echo \$\{SPLUNK_CMD_${n}\})"
      else
        # We do not want to iterate all, if one in the sequence is not set
        break
      fi
    done
  fi

  sudo -HEu ${SPLUNK_USER} tail -n 0 -f ${SPLUNK_HOME}/var/log/splunk/splunkd_stderr.log &
  wait
else
  "$@"
fi
