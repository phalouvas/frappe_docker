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
- Build worker image to include hrms with command in folder images/kainotomo `docker build --no-cache -f ./images/kainotomo/Containerfile . --tag phalouvas/erpnext-worker:14.40.0`
- change in file kainotomo.yml image from frappe/erpnext-worker:x.x.x to phalouvas/erpnext-worker:latest
- `docker compose --project-name frappe_docker -f kainotomo.yml up -d`
- `docker compose --project-name frappe_docker -f kainotomo.yml down`
- To create a new site with backend shell 
  - `bench new-site erpnext.kainotomo.com --db-name kainotomo_erpnext --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --set-default`
  - `bench --site erpnext.kainotomo.com enable-scheduler`
  - `bench new-site optimuslandcy.com --db-name optimusland --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app agriculture --install-app hrms --install-app erpnext`
  - `bench --site optimuslandcy.com enable-scheduler`
  - `bench new-site erp.detima.com --db-name detima --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext`
  - `bench --site erp.detima.com enable-scheduler`
  - `bench new-site theodoulouparts.com --db-name theodoulouparts --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --install-app cyprus_banks --install-app theodoulou`
  - `bench --site theodoulouparts.com enable-scheduler`
  - `bench new-site megarton.com --db-name megarton --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --install-app cyprus_banks --install-app pos_screen`
  - `bench --site megarton.com enable-scheduler`
  - `bench new-site erpdemo.kainotomo.com --db-name kainotomo_demo --mariadb-root-password pRep5v3Nzw_aMMV --admin-password pRep5v3Nzw_aMMV --install-app hrms --install-app erpnext --install-app payments`
  - `bench --site erpdemo.kainotomo.com enable-scheduler`

  ## How to schedule backups
  Add crontab entry for backup every 6 hours.

  ```
  0 */4 * * * docker compose --project-name frappe exec backend bench --site all backup --with-files > /dev/null
  ```
  
## Upgrade

### Development Server
- Fetch from remotes
- Change version for erpnext 14.40.0 and frappe 14.50.0 to latest
- Update accordingly file images/kainotomo/Containerfile with latest branches e.g. 
  - for erpnext from 14.40.0 to x.x.x
  - and frappe from 14.50.0 to x.x.x
- Create new image `docker build --no-cache -f ./images/kainotomo/Containerfile . --tag phalouvas/erpnext-worker:14.40.0` where 14.40.0 the erpnext version
- Run 
  - `docker compose --project-name frappe_docker -f kainotomo.yml down`
  - `docker compose --project-name frappe_docker -f kainotomo.yml up -d`
- Test locally
- Create version on github
- `docker push phalouvas/erpnext-worker:14.40.0`
- To delete old images in order to free up space use command `docker rmi -f phalouvas/erpnext-worker:x.x.x` where x.x.x the old version

### Production Server
- SSH on production server `ssh -i ~/.ssh/docker-1.pem azureuser@20.234.68.148`
- Activate github
  - `eval "$(ssh-agent -s)"`
  - `ssh-add ~/.ssh/github`
- `cd /home/azureuser/frappe_docker`
- `git pull`
- `docker pull phalouvas/erpnext-worker:14.40.0`
- Run 
  - `docker compose down`
  - `docker compose up -d`
- SSH in docker image if you want to run extra commands
  - Get image_id `docker ps -q -f name=backend*`
  - `docker exec -it image_id /bin/bash`
- To delete old images in order to free up space use command `docker rmi -f phalouvas/erpnext-worker:x.x.x` where x.x.x the old version
