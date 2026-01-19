# Frappe Docker

[![Build Stable](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml)
[![Build Develop](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml)

Docker images and orchestration for Frappe applications.

## What is this?

This repository handles the containerization of the Frappe stack, including the application server, database, Redis, and supporting services. It provides quick disposable demo setups, a development environment, production-ready Docker images and compose configurations for deploying Frappe applications including ERPNext.

## Repository Structure

```
frappe_docker/
├── docs/                 # Complete documentation
├── overrides/            # Docker Compose configurations for different scenarios
├── compose.yaml          # Base Compose File for production setups
├── pwd.yml               # Single Compose File for quick disposable demo
├── images/               # Dockerfiles for building Frappe images
├── development/          # Development environment configurations
├── devcontainer-example/ # VS Code devcontainer setup
└── resources/            # Helper scripts and configuration templates
```

> This section describes the structure of **this repository**, not the Frappe framework itself.

### Key Components

- `docs/` - Canonical documentation for all deployment and operational workflows
- `overrides/` - Opinionated Compose overrides for common deployment patterns
- `compose.yaml` - Base compose file for production setups (production)
- `pwd.yml` - Disposable demo environment (non-production)

## Documentation

**The official documentation for `frappe_docker` is maintained in the `docs/` folder in this repository.**

**New to Frappe Docker?** Read the [Getting Started Guide](docs/getting-started.md) for a comprehensive overview of repository structure, development workflow, custom apps, Docker concepts, and quick start examples.

If you are already familiar with Frappe, you can jump right into the [different deployment methods](docs/01-getting-started/01-choosing-a-deployment-method.md) and select the one best suited to your use case.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose v2](https://docs.docker.com/compose/)
- [git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git)

> For Docker basics and best practices refer to Docker's [documentation](http://docs.docker.com)

## Demo setup

The fastest way to try Frappe is to play in an already set up sandbox, in your browser, click the button below:

<a href="https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/frappe/frappe_docker/main/pwd.yml">
  <img src="https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png" alt="Try in PWD"/>
</a>

### Try on your environment

> **⚠️ Disposable demo only**
>
> **This setup is intended for quick evaluation. Expect to throw the environment away.** You will not be able to install custom apps to this setup. For production deployments, custom configurations, and detailed explanations, see the full documentation.

First clone the repo:

```sh
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

Then run:

```sh
docker compose -f pwd.yml up -d
```

Wait for a couple of minutes for ERPNext site to be created or check `create-site` container logs before opening browser on port `8080`. (username: `Administrator`, password: `admin`)

## Documentation Links

### [Getting Started Guide](docs/getting-started.md)

### [Frequently Asked Questions](https://github.com/frappe/frappe_docker/wiki/Frequently-Asked-Questions)

### [Getting Started](#getting-started)

### [Deployment Methods](docs/01-getting-started/01-choosing-a-deployment-method.md)

### [ARM64](docs/01-getting-started/03-arm64.md)

### [Container Setup Overview](docs/02-setup/01-overview.md)

### [Development](docs/05-development/01-development.md)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This repository is only for container related stuff. You also might want to contribute to:

## Resources

- [Frappe framework](https://github.com/frappe/frappe),
- [ERPNext](https://github.com/frappe/erpnext),
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
    --tag=phalouvas/erpnext-worker:version-15 \
    --file=images/azure/Containerfile .

  docker tag phalouvas/erpnext-worker:version-15 phalouvas/erpnext-worker:15.94.1
  docker push phalouvas/erpnext-worker:version-15
  docker push phalouvas/erpnext-worker:15.94.1

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
