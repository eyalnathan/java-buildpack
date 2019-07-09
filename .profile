#!/bin/bash

set -e

mkdir -p $HOME/tmp/ssl

echoerr() { echo "$@" 1>&2; }

if [[ -d $HOME/.java-buildpack/open_jdk_jre ]]; then
  echoerr "Found OpenJDK JRE ..."
  JRE_PATH=$HOME/.java-buildpack/open_jdk_jre
else
  echoerr "Using IBM JRE ..."
  JRE_PATH=$HOME/.java/jre
fi

for SERVICE in postgresql mongodb; do
  LEN="$(echo "${VCAP_SERVICES}" | jq --raw-output ".${SERVICE} | length")"
  for (( i=0; i<${LEN}; i++ )); do
    CA_BASE64="$(echo "${VCAP_SERVICES}" | jq --raw-output ".${SERVICE}[${i}].credentials.ca_base64")"
    if [[ "${CA_BASE64}" != "null" ]]; then
      echoerr "Importing CA certificate for ${SERVICE}[${i}]..."
      echo ${CA_BASE64} | base64 -d > $HOME/tmp/ssl/${SERVICE}${i}.crt
      ${JRE_PATH}/bin/keytool -keystore ${JRE_PATH}/lib/security/cacerts -storepass changeit -importcert -noprompt -alias mongodb${i} -file $HOME/tmp/ssl/${SERVICE}${i}.crt
      echoerr "Import finished successfully"
    fi
  done
done