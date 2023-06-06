[![Build Stable](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml)
[![Build Develop](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml)

Everything about [Frappe](https://github.com/frappe/frappe) and [ERPNext](https://github.com/frappe/erpnext) in containers.

# Getting Started

To get started, you need Docker, docker-compose and git setup on your machine. For Docker basics and best practices. Refer Docker [documentation](http://docs.docker.com).
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
- Build worker image to include hrms with command in folder images/kainotomo `docker build --no-cache -f ./images/kainotomo/Containerfile . --tag phalouvas/erpnext-worker:14.26.0`
- change in file kainotomo.yml image from frappe/erpnext-worker:x.x.x to phalouvas/erpnext-worker:latest
- `docker compose --project-name frappe_docker -f kainotomo.yml up -d`
- `docker compose --project-name frappe_docker -f kainotomo.yml down`
- To create a new site with backend shell 
  - `bench new-site erpnext.kainotomo.com --db-name kainotomo --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --set-default`
  - `bench --site erpnext.kainotomo.com enable-scheduler`
  - `bench new-site optimuslandcy.com --db-name optimusland --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app agriculture --install-app hrms --install-app erpnext`
  - `bench --site optimuslandcy.com enable-scheduler`
  - `bench new-site erp.detima.com --db-name detima --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext`
- Create staging sites
  - `bench new-site erptest.kainotomo.com --db-name kainotomo_test --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext`
  - `bench --site erptest.kainotomo.com enable-scheduler`
  - `bench new-site test.optimuslandcy.com --db-name optimusland_test --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app agriculture --install-app hrms --install-app erpnext`
  - `bench --site test.optimuslandcy.com enable-scheduler`
  - `bench new-site erpdemo.kainotomo.com --db-name kainotomo_demo --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --install-app payments`
  - `bench --site erpdemo.kainotomo.com enable-scheduler`
  
## Upgrade
- Fetch from remotes
- Update accordingly file images/kainotomo/Containerfile with latest branches e.g. 
  - for erpnext from 14.26.0 to x.x.x
  - and frappe from 14.37.1 to x.x.x
- Create new image `docker build --no-cache -f ./images/kainotomo/Containerfile . --tag phalouvas/erpnext-worker:14.26.0` where 14.26.0 the erpnext version
- Change version to file kainotomo.yml
- Run 
  - `docker compose --project-name frappe_docker -f kainotomo.yml down`
  - `docker compose --project-name frappe_docker -f kainotomo.yml up -d`
- Migrate
  - `bench --site erptest.kainotomo.com migrate`
  - `bench --site test.optimuslandcy.com migrate`
  - `bench --site erpnext.kainotomo.com migrate`
  - `bench --site optimuslandcy.com migrate`
  - `bench --site erpdemo.kainotomo.com migrate`
  - `bench --site erp.detima.com migrate`
- Create version on github
