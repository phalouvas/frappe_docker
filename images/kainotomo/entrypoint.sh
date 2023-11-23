#!/bin/bash

if [ \"$RUN_ENTRYPOINT\" = \"true\" ]; then
# Install additional Python packages
bench pip install invoice2data
bench pip install json2table

# Migrate the sites
bench --site erpdemo.kainotomo.com migrate
bench --site erpnext.kainotomo.com migrate
bench --site optimuslandcy.com migrate
bench --site erp.detima.com migrate
bench --site theodoulouparts.com migrate
bench --site megarton.com migrate

fi;

# Execute the CMD command provided when running the container
exec "$@"
