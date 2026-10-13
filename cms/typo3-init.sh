#!/bin/sh
set -e
cd /var/www/html

SETTINGS=typo3conf/system/settings.php

if [ ! -f "$SETTINGS" ]; then
  echo "[typo3-init] TYPO3 belum ter-install, menjalankan setup otomatis..."
  n=0
  until php typo3/sysext/core/bin/typo3 setup --no-interaction --force; do
    rm -f "$SETTINGS"
    n=$((n+1))
    if [ "$n" -ge 5 ]; then
      echo "[typo3-init] setup gagal 5x, cek pesan error di atas" >&2
      exit 1
    fi
    echo "[typo3-init] setup gagal, coba lagi 10 detik lagi ($n/5)"
    sleep 10
  done


  for f in typo3conf/sites/*/config.yaml; do
    if [ -f "$f" ]; then
      sed -i 's#^base: .*#base: /#' "$f"
    fi
  done
  rm -rf typo3temp/var/cache

  chown -R www-data:www-data typo3conf typo3temp fileadmin
  echo "[typo3-init] setup selesai"
else
  echo "[typo3-init] TYPO3 sudah ter-install, skip setup"
fi

rm -f FIRST_INSTALL

exec docker-php-entrypoint apache2-foreground
