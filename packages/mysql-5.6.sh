#!/bin/bash
# Install a custom MySQL 5.6 version - https://www.mysql.com
#
# To run this script on Codeship, add the following
# command to your project's setup commands:
# \curl -sSL https://raw.githubusercontent.com/codeship/scripts/master/packages/mysql-5.6.sh | bash -s
#
# Add the following environment variables to your project configuration
# (otherwise the defaults below will be used).
# * MYSQL_VERSION
# * MYSQL_PORT
#
MYSQL_VERSION=${MYSQL_VERSION:="5.6.43"}
MYSQL_PORT=${MYSQL_PORT:="3306"}
MYSQL_DL_URL="https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.43-linux-glibc2.12-x86_64.tar.gz"

set -e
MYSQL_DIR=${MYSQL_DIR:=$HOME/mysql-$MYSQL_VERSION}
CACHED_DOWNLOAD="${HOME}/cache/mysql-${MYSQL_VERSION}.tar.gz"

mkdir -p "${MYSQL_DIR}"
wget --continue --output-document "${CACHED_DOWNLOAD}" "${MYSQL_DL_URL}"
tar -xaf "${CACHED_DOWNLOAD}" --strip-components=1 --directory "${MYSQL_DIR}"
mkdir -p "${MYSQL_DIR}/data/mysql"
mkdir -p "${MYSQL_DIR}/socket"
mkdir -p "${MYSQL_DIR}/share"
mkdir -p "${MYSQL_DIR}/log"

echo "#
# The MySQL 5.6 database server configuration file.
#
[client]
port		= ${MYSQL_PORT}
protocol        = TCP

# This was formally known as [safe_mysqld]. Both versions are currently parsed.
[mysqld_safe]
socket		= ${MYSQL_DIR}/socket/mysqld.sock
nice		= 0

[mysqld]
user		= rof
pid-file	= ${MYSQL_DIR}/mysqld.pid
port		= ${MYSQL_PORT}
basedir		= ${MYSQL_DIR}/data
datadir		= ${MYSQL_DIR}/data/mysql
tmpdir		= /tmp
lc-messages-dir	= ${MYSQL_DIR}/share/english
skip-external-locking

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address		= 127.0.0.1

# * Fine Tuning
max_allowed_packet	= 16M
thread_stack		= 192K
thread_cache_size	= 8
innodb_use_native_aio	= 0

# * Query Cache Configuration
query_cache_limit	= 1M
query_cache_size        = 16M

# * Logging and Replication
log_error		= ${MYSQL_DIR}/log/error.log

[mysqldump]
quick
quote-names
max_allowed_packet	= 16M

[isamchk]
key_buffer		= 16M
" > "${MYSQL_DIR}/my.cnf"

(
  cd "${MYSQL_DIR}" || exit 1
  "${MYSQL_DIR}/scripts/mysql_install_db" --user=rof --defaults-file="${MYSQL_DIR}/my.cnf" --force
  "${MYSQL_DIR}/bin/mysqld_safe" --defaults-file="${MYSQL_DIR}/my.cnf" &
  sleep 10
)

"${MYSQL_DIR}/bin/mysql" --defaults-file="${MYSQL_DIR}/my.cnf" -u "${MYSQL_USER}" -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_PASSWORD}');"
"${MYSQL_DIR}/bin/mysql" --defaults-file="${MYSQL_DIR}/my.cnf" --version | grep "${MYSQL_VERSION}"
