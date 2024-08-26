[![Build Stable](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml)
[![Build Develop](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml)

Everything about [Frappe](https://github.com/frappe/frappe) and [ERPNext](https://github.com/frappe/erpnext) in containers.

# Getting Started

To get started you need [Docker](https://docs.docker.com/get-docker/), [docker-compose](https://docs.docker.com/compose/), and [git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git) setup on your machine. For Docker basics and best practices refer to Docker's [documentation](http://docs.docker.com).
After that, clone this repo:

```sh
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

### Try in Play With Docker

<a href="https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/frappe/frappe_docker/main/pwd.yml">
  <img src="https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png" alt="Try in PWD"/>
</a>

Wait for 5 minutes for ERPNext site to be created or check `create-site` container logs before opening browser on port 8080. (username: `Administrator`, password: `admin`)

# Documentation

### [Production](#production)

- [List of containers](docs/list-of-containers.md)
- [Single Compose Setup](docs/single-compose-setup.md)
- [Environment Variables](docs/environment-variables.md)
- [Single Server Example](docs/single-server-example.md)
- [Setup Options](docs/setup-options.md)
- [Site Operations](docs/site-operations.md)
- [Backup and Push Cron Job](docs/backup-and-push-cronjob.md)
- [Port Based Multi Tenancy](docs/port-based-multi-tenancy.md)
- [Migrate from multi-image setup](docs/migrate-from-multi-image-setup.md)
- [running on linux/mac](docs/setup_for_linux_mac.md)

### [Custom Images](#custom-images)

- [Custom Apps](docs/custom-apps.md)
- [Build Version 10 Images](docs/build-version-10-images.md)

### [Development](#development)

- [Development using containers](docs/development.md)
- [Bench Console and VSCode Debugger](docs/bench-console-and-vscode-debugger.md)
- [Connect to localhost services](docs/connect-to-localhost-services-from-containers-for-local-app-development.md)

### [Troubleshoot](docs/troubleshoot.md)

# Contributing

If you want to contribute to this repo refer to [CONTRIBUTING.md](CONTRIBUTING.md)

This repository is only for container related stuff. You also might want to contribute to:

- [Frappe framework](https://github.com/frappe/frappe#contributing),
- [ERPNext](https://github.com/frappe/erpnext#contributing),
- [Frappe Bench](https://github.com/frappe/bench).

# Panayiotis Notes
## How to build containers.
- Change the .env `FRAPPE_SITE_NAME_HEADER=erpnext.kainotomo.com`
- `docker compose -f compose.yaml -f overrides/compose.noproxy.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml config > kainotomo.yml`
- Build worker image to include hrms with command in folder images/kainotomo `docker build --no-cache -f ./images/kainotomo/Containerfile . --tag phalouvas/erpnext-worker:14.61.1`
- change in file kainotomo.yml image from frappe/erpnext-worker:x.x.x to phalouvas/erpnext-worker:latest
- `docker compose --project-name frappe_docker -f kainotomo.yml up -d`
- `docker compose --project-name frappe_docker -f kainotomo.yml down`
- To create a new site with backend shell 
  ```shell

  bench new-site development.kainotomo.com --db-name kainotomo_erpnext --mariadb-root-password xxxxxxxx --admin-password xxxxxxxx --install-app hrms --install-app erpnext --install-app payments --install-app paypalstandardpayments --install-app digital_subscriptions --install-app vies_validation --set-default
  bench --site erpnext.kainotomo.com enable-scheduler
  ```

  ## How to schedule backups
  Add crontab entry for backup every 6 hours.

  ```
  0 */4 * * * docker compose --project-name frappe exec backend bench --site all backup --with-files > /dev/null
  ```

## How to create containers
- `docker compose --project-name phpmyadmin --env-file ~/gitops/phpmyadmin.env -f overrides/compose.phpmyadmin.yaml up -d`

## Upgrade

### Development Server
- Fetch from remotes
- Fix version 14.61.1 to new in repository gitops
- Add any necessary apps in file ~/kainotomo/frappe_docker/images/custom/apps.json

#### V14
- Export apps to variable and build image
  ```shell

  export APPS_JSON_BASE64=$(base64 -w 0 ~/frappe_docker/images/custom/v14.json)

  docker build  --no-cache --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
    --build-arg=FRAPPE_BRANCH=version-14 \
    --build-arg=PYTHON_VERSION=3.11.4 \
    --build-arg=NODE_VERSION=16.18.0 \
    --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
    --tag=phalouvas/erpnext-worker:14.62.4 \
    --file=images/custom/Containerfile .

  docker push phalouvas/erpnext-worker:14.62.4
  docker tag phalouvas/erpnext-worker:14.62.4 phalouvas/erpnext-worker:version-14
  docker push phalouvas/erpnext-worker:version-14

    ```

#### V15
- Export apps to variable and build image
  ```shell

  export APPS_JSON_BASE64=$(base64 -w 0 ~/frappe_docker/images/azure/v15.json)

  docker build  --no-cache --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
    --build-arg=FRAPPE_BRANCH=version-15 \
    --build-arg=PYTHON_VERSION=3.11.6 \
    --build-arg=NODE_VERSION=18.18.2 \
    --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
    --tag=phalouvas/erpnext-worker:15.33.5 \
    --file=images/azure/Containerfile .

  docker push phalouvas/erpnext-worker:15.33.5
  docker tag phalouvas/erpnext-worker:15.33.5 phalouvas/erpnext-worker:version-15
  docker push phalouvas/erpnext-worker:version-15

    ```

### Update localhost
- `docker compose --project-name erpnext-v15 down`
- `docker compose --project-name erpnext-v15 -f ~/gitops/localhost/erpnext-v15.yaml up -d`
- `docker images | grep erpnext`
- To delete old images in order to free up space use command `docker rmi -f phalouvas/erpnext-worker:x.x.x` where x.x.x the old version

### Production Server docker-1
- SSH on production server `ssh -i ~/.ssh/docker-1.pem azureuser@20.234.68.148`
- Run deploy script
  ```shell
    ./gitops/docker-1/deploy.sh
  ```
- SSH in docker image if you want to run extra commands
  - Get image_id `docker ps -f name=backend*`
  - `docker exec -it image_id /bin/bash`
  - `bench --site all migrate`
- `docker images | grep erpnext`
- To delete old images in order to free up space use command `docker rmi -f phalouvas/erpnext-worker:x.x.x` where x.x.x the old version

### Production Server docker-2
- SSH on production server `ssh -i ~/.ssh/docker-2.pem azureuser@51.138.190.62`
- Run deploy script
  ```shell
    ./gitops/docker-2/deploy.sh
  ```
- SSH in docker image if you want to run extra commands
  - Get image_id `docker ps -f name=backend*`
  - `docker exec -it image_id /bin/bash`
  - `bench --site all migrate`
- `docker images | grep erpnext`
- To delete old images in order to free up space use command `docker rmi -f phalouvas/erpnext-worker:x.x.x` where x.x.x the old version
