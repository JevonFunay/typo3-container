#!/bin/sh
set -e
cd /var/www/html

if [ ! -f typo3conf/system/settings.php ]; then
  php typo3/sysext/core/bin/typo3 setup --no-interaction --force
  sed -i 's#^base: .*#base: /#' typo3conf/sites/main/config.yaml
  rm -rf typo3temp/var/cache
  chown -R www-data:www-data typo3conf typo3temp fileadmin
fi

rm -f FIRST_INSTALL
exec docker-php-entrypoint apache2-foreground