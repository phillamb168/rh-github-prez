#!/bin/bash
n=0
until [ $n -ge 5 ]
do
   sudo service httpd restart && echo "test" >> /tmp/testrestart.txt && break  # substitute your command here
   n=$[$n+1]
   sleep 15
done
