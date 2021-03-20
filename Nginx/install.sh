#!/bin/bash

# Task
# install Nginx and creat start page for web-site

# update repositories and packages 
apt update -y
apt upgrade -y

# Install Nginx
apt install nginx -y
echo "status nginx"
systemctl status nginx


# creat start page for web-site
echo "<html>
<head>
<title>All Work</title>
</head>
<body>
<H1>Hello</H1>
<P> if you look this text then your web-server is working </P>
</body>
</html>" > /var/www/html/index.html
systemctl restart nginx
