#!/bin/bash
cd /var/www/deploy/rh-github-prez/code/web/sites/default
sudo s3fs rh-github-prez-public-files:/ -o iam_role="s3_access_role" -o use_cache=/tmp -o allow_other -o uid=48,umask=0002 -o gid=48 -o mp_umask=007 -o multireq_max=5 files/
cd /mnt/web
sudo s3fs rh-github-prez-private-files:/ -o iam_role="s3_access_role" -o use_cache=/tmp -o allow_other -o uid=48,umask=0002 -o gid=48 -o mp_umask=007 -o multireq_max=5 private/
