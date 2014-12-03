# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.11

# Set correct environment variables.
ENV HOME /root

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh
# Disable cron
RUN rm -rf /etc/service/cron

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

# Install diaspora dependencies
RUN apt-get -y install build-essential curl git imagemagick libmagickwand-dev nodejs redis-server libcurl4-openssl-dev libxml2-dev libxslt-dev libmysqlclient-dev

# Install Mysql
RUN apt-get -y install mysql-server

RUN add-apt-repository -y ppa:brightbox/ruby-ng

RUN apt-get update
RUN apt-get -y install ruby2.1-dev
RUN gem install bundler
RUN apt-get -y install nodejs-legacy

# minimize mysql allocations
RUN echo '[mysqld]\ninnodb_data_file_path = ibdata1:10M:autoextend\ninnodb_log_file_size = 10KB\ninnodb_file_per_table = 1' > /etc/mysql/conf.d/small.cnf
RUN sed -i 's_^socket\s*=.*_socket = /tmp/mysqld.sock_g' /etc/mysql/*.cnf && ln -s /tmp/mysqld.sock /var/run/mysqld/mysqld.sock
RUN rm -rf /var/lib/mysql/* && mysql_install_db && chown -R mysql: /var/lib/mysql

# Setup mysql//mysql user
RUN /usr/sbin/mysqld & \
    sleep 10s &&\
    echo "GRANT ALL ON *.* TO mysql@'%' IDENTIFIED BY 'mysql' WITH GRANT OPTION; FLUSH PRIVILEGES; CREATE SCHEMA app;" | mysql

# Setup services
RUN mkdir /etc/service/mysql
ADD mysql.sh /etc/service/mysql/run

RUN mkdir /etc/service/app
ADD app.sh /etc/service/app/run

RUN mkdir /etc/service/redis
ADD redis.sh /etc/service/redis/run

ADD . /opt/app
RUN rm -rf /opt/app/.git
RUN cd /opt/app/config && cp database.yml.sandstorm database.yml && cp diaspora.yml.sandstorm diaspora.yml
RUN /usr/sbin/mysqld & \
    cd /opt/app && bundle install && bundle exec rake db:create db:schema:load
# bash -c 'source /usr/local/rvm/scripts/rvm && rvm use ruby-2.1.3 && cd /opt/app && RAILS_ENV=production bundle install --without test development && RAILS_ENV=production  bundle exec rake db:create db:schema:load && bundle exec rake assets:precompile'

EXPOSE 33411

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -rf /usr/share/vim /usr/share/doc /usr/share/man /var/lib/dpkg /var/lib/belocs /var/lib/ucf /var/cache/debconf /var/log/*.log
