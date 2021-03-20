#!/bin/bash

#Chek status Nginx
echo "
Chek status Nginx"
sudo systemctl status nginx | grep active

if [ -f /var/run/nginx.pid ];
  then echo "
  Nginx is running";
fi

#Chek port 80
echo "
Chek port 80"
sudo lsof -i TCP:80

#Chek syntax or system error
echo "
Chek syntax or system error"
sudo nginx -t

#Chek avialability content
echo "
Chek avialability content"
sudo find /var/www/html -name *.html