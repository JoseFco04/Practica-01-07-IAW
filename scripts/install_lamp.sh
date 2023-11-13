#!/bin/bash

#Muestra todos los comandos que se van ejecutando
set -ex

#Actualizamos los repositorios
apt update

#Actualizamos los paquetes
#apt upgrade -y

#Instalamos el servidor web Apache
sudo apt install apache2 -y

#Instalamos el gestor de bases de datos MySQL
sudo apt install mysql-server -y

#Instalamos PHP
apt install php libapache2-mod-php php-mysql -y

# Copiamos el archivo conf de apache 
cp ../conf/000-default.conf /etc/apache2/sites-available

#Reiniciamos el servicio de Apache
systemctl restart apache2

# Copiamos el archivo de php 
cp ../php/index.php /var/www/html

#Modificamos el propietario y el grupo del directorio /var/www/html
chown -R www-data:www-data /var/www/html