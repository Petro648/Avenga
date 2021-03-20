#!/bin/bash

# Task
# monitoring Web-server from your PC 

#connect to Web-server

echo "Please enter IP-adress web-serwer "
read IP
echo "Please enter username "
read USER

ssh -t $USER@$IP  "$( < ./monitoryng2.sh)"
