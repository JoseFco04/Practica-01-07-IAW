# Practica-01-07 Jose Francisco León López
## En esta práctica vamos a automatizar la instalación de wordpress en nuestra máquina de AWS
### Usaremos la misma máquina que la práctica 06 y los mismos scripts de configuración a excepción del deploy, con el que vamos a desplegar el wordpress.

### Los archivos de configuración que va a tener esta máquina son los siguientes:
### El 000-default.conf que su contenido va a ser el siguiente:
~~~
ServerSignature Off
ServerTokens Prod
<VirtualHost *:80>
  #ServerName www.example.com
  DocumentRoot /var/www/html
  DirectoryIndex index.php index.html

  <Directory "/var/www/html">
    AllowOverride All
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
~~~
### Y el htaccess cuyo contenido es el siguiente:
~~~
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
~~~
### Tenemos otro archivo de configuración para las variables que es el archivo .env que es el siguiente:
~~~
# Configuramos las variables
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=josefco
WORDPRESS_DB_PASSWORD=1234
WORDPRESS_DB_HOST=localhost
IP_CLIENTE_MYSQL=localhost

WORDPRESS_TITLE="Sitio web de IAW Jose"
WORDPRESS_ADMIN_USER=admin 
WORDPRESS_ADMIN_PASS=admin 
WORDPRESS_ADMIN_EMAIL=josefco@iaw.com

CB_MAIL=josefco@iaw.com
CB_DOMAIN=practica9frontjose.ddns.net

TEMA=sydney
PLUGIN=bbpress
PlUGIN2=wps-hide-login
~~~
#### Aquí tenemos todas las variables que vamos a usar a la hora de automatizar e instalar wordpress en nuestra máquina.

## Los scripts que tenemos que lanzar para hacerlo son los siguientes:
### El primero es el install_lamp que ya hemos usado en prácticas anteriores y paso por paso sería así:
#### Primero usamos este commando que nos muestra todos los comandos que se van ejecutando
~~~
set -ex
~~~
#### Actualizamos los repositorios
~~~
apt update
~~~
#### Actualizamos los paquetes (este solo lo hacemos una vez)
~~~
apt upgrade -y
~~~
#### Instalamos el servidor web Apache
~~~
sudo apt install apache2 -y
~~~
#### Instalamos el gestor de bases de datos MySQL
~~~
sudo apt install mysql-server -y
~~~
#### Instalamos PHP
~~~
apt install php libapache2-mod-php php-mysql -y
~~~
#### Copiamos el archivo conf de apache 
~~~
cp ../conf/000-default.conf /etc/apache2/sites-available
~~~
#### Reiniciamos el servicio de Apache
~~~
systemctl restart apache2
~~~
#### Copiamos el archivo de php 
~~~
cp ../php/index.php /var/www/html
~~~
#### Modificamos el propietario y el grupo del directorio /var/www/html
~~~
chown -R www-data:www-data /var/www/html
~~~
### Ahora tenemos que ejecutar el script del letsencrypt para añadirle el dominio a la máquina.

#### Usamos este comando para que nos muestre todos los comandos que se van ejecutando y si hay un fallo que deje de ejecutar el script.
~~~
set -ex
~~~
#### Actualizamos los repositorios
~~~
apt update
~~~
#### Actualizamos los paquetes
~~~
apt upgrade -y
~~~
#### Importamos el archivo de variables .env
~~~
source .env
~~~
#### Instalamos y actualizamos snapd
~~~
snap install core && snap refresh core
~~~
#### Eliminamos cualquier instalación previa de certbot con apt
~~~
apt remove certbot
~~~
#### Instalamos la aplicación certbot
~~~
snap install --classic certbot
~~~
#### Creamos un alias para la aplicación certbot
~~~
ln -fs /snap/bin/certbot /usr/bin/certbot
~~~
#### Ejecutamos el comando certbot
~~~
certbot --apache -m $CB_MAIL --agree-tos --no-eff-email -d $CB_DOMAIN --non-interactive
~~~
### Y por último el script del deploy del wordpress que en vez de ser dos como la anterior práctica es solo uno y lo vamos a automatizar de la siguiente forma :

#### Muestra todos los comandos que se van ejecutando
~~~
set -ex
~~~
#### Actualizamos los repositorios
~~~
apt update
~~~
#### Actualizamos los paquetes (Este comando solon hay que ejecutarlo una vez en la máquina)
~~~
apt upgrade -y
~~~
#### Importamos el archivo de variables .env
~~~
source .env
~~~
#### Eliminamos descargas previas 
~~~
rm -rf /tmp/wp-cli.phar
~~~
#### Descargamos la utilidaad wp-cli 
~~~
wget  https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
~~~
#### Le asignamos permisos de ejecución al archivo wp-cli.phar
~~~
chmod +x /tmp/wp-cli.phar
~~~
#### Movemos la utilidad wp-cli al directorio /usr/local/bin
~~~
mv /tmp/wp-cli.phar /usr/local/bin/wp
~~~
#### Eliminamos instalaciones previas de wordpress
~~~
rm -rf /var/www/html/*
~~~
#### Descargamos el código fuente de WordPress en /var/www/html
~~~
wp core download --locale=es_ES --path=/var/www/html --allow-root
~~~
#### Creamos la base de datos y el usuario de la base de datos 
~~~
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
~~~
#### Creamos el archivo wp-config 
~~~
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --path=/var/www/html \
  --allow-root
~~~
#### Instalamos worpress
~~~
  wp core install \
  --url=$CB_DOMAIN \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASS \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root
~~~
#### Actualizamos los plugins 
~~~
wp core update --path=/var/www/html --allow-root
~~~
#### Actualizamos los temas 
~~~
wp theme update --all --path=/var/www/html --allow-root
~~~
#### Instalo un tema
~~~
wp theme install $TEMA --activate --path=/var/www/html --allow-root
~~~
#### Actualizamos los plugins
~~~
wp plugin update --all --path=/var/www/html --allow-root
~~~
#### Instalar y activar un  plugin
~~~
wp plugin install $PLUGIN --activate --path=/var/www/html --allow-root
wp plugin install $PLUGIN2 --activate --path=/var/www/html --allow-root 
~~~
#### Copiamos el nuevo archivo .htaccess
~~~
cp ../htaccess/.htaccess /var/www/html
~~~
#### Por último modificamos el propietario y el grupo del directorio /var/www/html
~~~
chown -R www-data:www-data /var/www/html
~~~
### Y ya tendríamos configurado el wordpress automatizado para que nos entre directamente y nos salga la página de wordpress con el tema que le hemos istalado.
