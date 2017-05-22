FROM centos/nginx-18-centos7 

MAINTAINER Diogo Cordeiro <dcordeiro@vivasuperstars.com>

EXPOSE 8080

ENV PHP_VERSION=7.0 \
    PATH=$PATH:/opt/rh/rh-php70/root/usr/bin

LABEL io.k8s.description="Nginx and PHP 7 (FPM)" \
      io.k8s.display-name="Nginx and PHP 7 (FPM)" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,nginx,php,php7,php70,php-fpm"

USER root

RUN curl 'https://setup.ius.io/' -o setup-ius.sh && \
    bash setup-ius.sh
RUN rm setup-ius.sh

RUN yum install -y --setopt=tsflags=nodocs --enablerepo=centosplus \
    php70u-fpm-nginx \
    php70u-cli \
    php70u-gd \
    php70u-imap \
    php70u-json \
    php70u-mbstring \
    php70u-mcrypt \
    php70u-opcache \
    php70u-pdo \
    php70u-pdo \
    php70u-xml

RUN yum clean all -y

COPY ./s2i/bin/ $STI_SCRIPTS_PATH

COPY ./contrib/ /opt/app-root

RUN cp /opt/app-root/etc/conf.d/php-fpm/pool.conf /etc/php-fpm.d/www.conf
RUN cp /opt/app-root/etc/conf.d/php-fpm/fpm.conf /etc/php-fpm.conf

RUN mkdir /tmp/sessions && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /var/log/nginx && \
    touch /var/log/nginx/error.log && \
    touch /var/log/nginx/access.log && \
    chown -R 1001:0 /var/log/nginx && \
    chown -R 1001:0 /var/lib/nginx && \
    chown -R 1001:0 /opt/app-root /tmp/sessions && \
    chmod -R a+rwx /tmp/sessions && \
    chmod -R a+rwx /var/log/nginx && \
    chmod -R a+rwx /var/lib/nginx && \
    chmod -R ug+rwx /var/log/nginx && \
    chmod -R ug+rwx /var/lib/nginx && \
    chmod -R ug+rwx /opt/app-root && \
    chmod +x /opt/app-root/services.sh

USER 1001

CMD $STI_SCRIPTS_PATH/run


