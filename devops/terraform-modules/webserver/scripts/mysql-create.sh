#!/bin/bash
source /etc/environment
touch /tmp/db-env.txt
echo '#!/bin/bash' > /tmp/db-env.txt
cat /etc/environment >> /tmp/db-env.txt
envtext="`head -n 1 /etc/environment`"
sudo echo "export ${envtext}" >> /etc/sysconfig/httpd
redistext="`sed -n 2p /etc/environment`"
sudo echo "export ${redistext}" >> /etc/sysconfig/httpd
sudo service httpd restart
