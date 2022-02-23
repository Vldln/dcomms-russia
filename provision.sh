#!/bin/bash
if [[ -z "${DWEB_DOMAIN}" ]]
then
  echo "## Error"
  echo "Please set a DWEB_DOMAIN environment variable before running this script"
  echo "For example: DWEB_DOMAIN=matrix.org ./provision"
  exit 1
fi

# Replace dots with dashes
export DWEB_FRIENDLY_DOMAIN="${DWEB_DOMAIN//./_}"
echo "## Removing existing dwebstack"
docker stack rm dwebstack-${DWEB_FRIENDLY_DOMAIN}
docker network rm caddy-${DWEB_FRIENDLY_DOMAIN}
echo "## Sleeping for 10 seconds"
sleep 10
echo "## Removing synapse-data"
echo "## Generating synapse config"
docker run -it --rm \
    --mount type=volume,src=synapse_data_tmp,dst=/data \
    -e SYNAPSE_SERVER_NAME=$DWEB_DOMAIN \
    -e SYNAPSE_REPORT_STATS=no \
    -e SYNAPSE_DATA_DIR=/data \
    matrixdotorg/synapse:v1.53.0 generate
echo "## Copying config files into docker swarm configs"
cp -a /var/lib/docker/volumes/synapse_data_tmp/_data/homeserver.yaml ./conf/synapse/$DWEB_DOMAIN.homeserver.yaml
cp -a /var/lib/docker/volumes/synapse_data_tmp/_data/$DWEB_DOMAIN.signing.key ./conf/synapse/$DWEB_DOMAIN.signing.key
cp -a /var/lib/docker/volumes/synapse_data_tmp/_data/$DWEB_DOMAIN.log.config ./conf/synapse/$DWEB_DOMAIN.log.config

#sed -i 's/data\/media_store/data2\/media_store/g' ./conf/synapse/$DWEB_DOMAIN.homeserver.yaml

echo "## Provisioning dwebstack"
DWEB_DOMAIN=$DWEB_DOMAIN DWEB_FRIENDLY_DOMAIN=$DWEB_FRIENDLY_DOMAIN docker stack deploy -c docker-compose.yml dwebstack-${DWEB_FRIENDLY_DOMAIN}