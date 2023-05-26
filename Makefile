ansible-galaxy:
	ansible-galaxy install -r ansible/requirements.yml

ansible-playbook:
	ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -u acouvreur -K

install-docker-client:
	wget https://download.docker.com/linux/static/stable/x86_64/docker-24.0.1.tgz
	tar xzvf docker-24.0.1.tgz
	sudo cp docker/* /usr/bin/
	rm -rf docker docker-24.0.1.tgz
	docker context create raspberrypi --description "My Raspberry Pi 4" --docker "host=ssh://acouvreur@192.168.0.2:22"
	docker context use raspberrypi

DOCKER_CONFIG = ${HOME}/.docker
install-docker-compose:
	mkdir -p ${DOCKER_CONFIG}/cli-plugins
	curl -SL https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64 -o ${DOCKER_CONFIG}/cli-plugins/docker-compose
	chmod +x ${DOCKER_CONFIG}/cli-plugins/docker-compose

create-proxy-network:
	docker network create --attachable proxy

start-pihole:
	docker compose --env-file .env -p pihole -f services/pihole/compose.yml up -d

start-proxy:
	docker compose --env-file .env -p proxy -f services/proxy/compose.yml up -d

start-media:
	docker compose --env-file .env -p media -f services/media/compose.yml up -d

start-homeassistant:
	docker compose --env-file .env -p hass -f services/homeassistant/compose.yml up -d

start-wireguard:
	docker compose --env-file .env -p wireguard -f services/wireguard/compose.yml up -d

start-backup:
	docker compose --env-file .env -p backup -f services/backup/compose.yml up -d

start-portainer:
	docker compose --env-file .env -p portainer -f services/portainer/compose.yml up -d