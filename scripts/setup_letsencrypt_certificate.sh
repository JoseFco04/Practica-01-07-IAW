#!/bin/bash

# Muestra todos los comandos que se van ejecutando
set -ex

# Actualizamos los repositorios
apt update

# Actualizamos los paquetes
#apt upgrade -y

# Importamos el archivo de variables .env
source .env

# Instalamos y actualizamos snapd
snap install core && snap refresh core

# Eliminamos cualquier instalación previa de certbot con apt
apt remove certbot

# Instalamos la aplicación certbot
snap install --classic certbot

# Creamos un alias para la aplicación certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# Ejecutamos el comando certbot
certbot --apache -m $CB_MAIL --agree-tos --no-eff-email -d $CB_DOMAIN --non-interactive