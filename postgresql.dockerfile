FROM debian:bullseye-slim
ARG PGSQL_DOMAIN="pascual.com.ph"
ARG PGSQL_CLIENTS='192.168.1.0\/24'
ARG PGSQL_SERVERS='172.16.1.0\/24'
LABEL service="postgresql"
RUN sed -i '${s/$/ contrib non-free/}' /etc/apt/sources.list || exit 1 && \
  apt-get update || exit 1 && \
  apt-get upgrade -y || exit 1 && \
  apt-get install -y apt-utils postgresql-12 dumb-init wget || exit 1 && \
  apt-get clean || exit 1 && \
  apt-get autoremove --purge || exit 1 && \
  groupmod -g 65123 postgres || exit 1 && \
  usermod -u 65123 -g users -G postgres postgres || exit 1 && \
  echo "clear" > /var/lib/postgresql/.bash_logout || exit 1 && \
  sed -i -e "/^#listen_addresses/i listen_addresses = \'0.0.0.0\'" \
  -e "s/ssl-cert-snakeoil/${PGSQL_DOMAIN}/g" \
  -e "s/^data_directory.*$/data_directory = '\/data'/g" \
  /etc/postgresql/12/main/postgresql.conf || exit 1 && \
  rm -f /etc/postgresql/12/main/pg_hba.conf || exit 1 && \
  wget -q -c -O /etc/postgresql/12/main/pg_hba.conf https://raw.githubusercontent.com/bintut/kaban/master/pg_hba.conf || exit 1 && \
  sed -i -e "s/PGSQL_CLIENTS/${PGSQL_CLIENTS}/g" -e "s/PGSQL_SERVERS/${PGSQL_SERVERS}/g" /etc/postgresql/12/main/pg_hba.conf || exit 1 && \
  chown -R postgres:users /etc/postgresql /etc/postgresql-common /usr/lib/postgresql /usr/share/postgresql \
  /usr/share/postgresql-common /var/lib/postgresql /var/log/postgresql /var/run/postgresql || exit 1 && \
  rm -Rf /tmp/* /var/tmp/* || exit 1 && \
  find /var/log/ -type f -exec truncate -s 0 '{}' \;
USER postgres
WORKDIR /var/lib/postgresql
VOLUME /data
EXPOSE 5432/tcp
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
