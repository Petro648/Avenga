#!/bin/bash

echo "connetction from IP:" > statistic.nginx

less /var/log/nginx/access.log | cut -d' ' -f1 | sort | uniq -c >> statistic.nginx

echo "unique IP:" >> statistic.nginx

less /var/log/nginx/access.log | cut -d' ' -f1 | sort | uniq -c | wc -l >> statistic.nginx

cat ./statistic.nginx


