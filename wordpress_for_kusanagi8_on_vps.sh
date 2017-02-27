#!/bin/bash

#   さくらのVPSのKUSANAGI8 環境に WordPress をセットアップするスクリプトです。
#   このスクリプトを使うと各種パスワードを自動生成します。
#   https://サーバのIPアドレス/
#   ※ セットアップには5〜10分程度時間がかかります。
#   （このスクリプトは、KUSANAGI8でのみ動作します）
#   
#   セットアップ後は、kusanagiのSSL(Let's Encrypt)設定や、WordPress のURL設定をIPアドレスからドメイン名に変更する設定の実施をおすすめします。
# Command
# 
# curl -O https://raw.githubusercontent.com/terao/eisaku/master/wordpress_for_kusanagi8_on_vps.sh
# 
# chmod 700 wordpress_for_kusanagi8_on_vps.sh
# 
# ./wordpress_for_kusanagi8_on_vps.sh terao@example.jp  2>&1 | tee -a wordpress_for_kusanagi8_on_vps.log
# #(teeコマンドでログに出力するとパスワードをコピペできなかったときに便利です。必ず、パスワードをコピーしたらログを削除してください)
#
# # 最後にサーバのrebootを推奨します
# reboot
# 

echo "## start date";
date

echo "## set default variables";

KUSANAGI_PASSWD=`mkpasswd -l 32 -d 9 -c 9 -C 9 -s 0 -2`
DBROOT_PASSWD=`mkpasswd -l 32 -d 9 -c 9 -C 9 -s 0 -2`
WP_ADMIN_USER="admin_`mkpasswd -l 5 -C 0 -s 0`"
WP_ADMIN_PASSWD=`mkpasswd -l 32 -d 9 -c 9 -C 9 -s 0 -2`
WP_TITLE="ICHIGEKI WordPress on KUSANAGI"
WP_ADMIN_MAIL="$1"

TERM=xterm

IPADDRESS0=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`
WPDB_USERNAME="wp_`mkpasswd -l 10 -C 0 -s 0`"
WPDB_PASSWORD=`mkpasswd -l 32 -d 9 -c 9 -C 9 -s 0 -2`


cat << EOS
## infomation
- Server Infomation
Web Server : Nginx
PHP Type   : hhvm
IP Address : $IPADDRESS0

- Linux User Infomation
kusanagi user Password     : $KUSANAGI_PASSWD

- MariaDB Infomation
MariaDB root Password      : $DBROOT_PASSWD
MariaDB Wordpress Username : $WPDB_USERNAME
MariaDB Wordpress Password : $WPDB_PASSWORD

- WordPress Infomation
Wordpress URL              : https://$IPADDRESS0/
Wordpress Admin Username   : $WP_ADMIN_USER
Wordpress Admin Password   : $WP_ADMIN_PASSWD
Wordpress Title            : $WP_TITLE
Wordpress Admin Email      : $WP_ADMIN_MAIL

EOS

echo "## yum update";
yum --enablerepo=remi,remi-php56 update -y || exit 1
sleep 10

#---------START OF kusanagi---------#
echo "## Kusanagi init";
kusanagi init --tz Asia/Tokyo --lang ja --keyboard ja \
  --passwd "$KUSANAGI_PASSWD" --no-phrase \
  --dbrootpass "$DBROOT_PASSWD" \
  --nginx --hhvm || exit 1

echo "## Kusanagi provision";
kusanagi provision \
  --WordPress  --wplang ja \
  --fqdn $IPADDRESS0 \
  --no-email  \
  --dbname $WPDB_USERNAME --dbuser $WPDB_USERNAME --dbpass $WPDB_PASSWORD \
  default_profile  || exit 1

#---------END OF kusanagi---------#

#---------START OF WordPrss---------#

# バックエンドで sudo が動くように設定変更
#sed 's/^Defaults    requiretty/#Defaults    requiretty/' -i.bk  /etc/sudoers  || exit 1

# ここからWordPress の設定ファイル作成
echo "## Kusanagi wordpress config";
sudo -u kusanagi -i /usr/local/bin/wp core config \
  --dbname=$WPDB_USERNAME \
  --dbuser=$WPDB_USERNAME \
  --dbpass=$WPDB_PASSWORD \
  --dbhost=localhost --dbcharset=utf8mb4 --extra-php \
  --path=/home/kusanagi/default_profile/DocumentRoot/ \
  < /usr/lib/kusanagi/resource/wp-config-sample/ja/wp-config-extra.php  || exit 1

echo "## Kusanagi wordpress core install";
sudo -u kusanagi  -i /usr/local/bin/wp core install \
  --url=$IPADDRESS0 \
  --title="$WP_TITLE" \
  --admin_user=$WP_ADMIN_USER  \
  --admin_password=$WP_ADMIN_PASSWD \
  --admin_email="$WP_ADMIN_MAIL" \
  --path=/home/kusanagi/default_profile/DocumentRoot/  || exit 1

# sudo の変更を元に戻す
#/bin/cp /etc/sudoers.bk /etc/sudoers  || exit 1

#---------END OF WordPrss---------#


echo "## finished!";


cat << EOS
- KUSANAGI Server Infomation
Web Server      : Nginx
PHP Type        : hhvm
Default Profile : default_profile
IP Address      : $IPADDRESS0

- Linux User Infomation
kusanagi user Password     : $KUSANAGI_PASSWD

- MariaDB Infomation
MariaDB root Password      : $DBROOT_PASSWD
MariaDB Wordpress Username : $WPDB_USERNAME
MariaDB Wordpress Password : $WPDB_PASSWORD
MariaDB Host               : localhost
MariaDB Charset            : utf8mb4

- WordPress Infomation
Wordpress URL              : https://$IPADDRESS0/
Wordpress Admin Username   : $WP_ADMIN_USER
Wordpress Admin Password   : $WP_ADMIN_PASSWD
Wordpress Title            : $WP_TITLE
Wordpress Admin Email      : $WP_ADMIN_MAIL
Document Root              : /home/kusanagi/default_profile/DocumentRoot/

EOS

echo "## Please reboot the server yourself.";
echo "## finish date";
date

exit 0
