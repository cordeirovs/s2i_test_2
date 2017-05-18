FROM centos/s2i-base-centos7

# This image provides an Apache+PHP environment for running PHP
# applications.

EXPOSE 8080

ENV PHP_VERSION=7.0 \
    PATH=$PATH:/opt/rh/rh-php70/root/usr/bin

LABEL io.k8s.description="Platform for building and running PHP 7.0 applications" \
      io.k8s.display-name="Apache 2.4 with PHP 7.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,php,php70,rh-php70"

# Labels consumed by Red Hat build service
LABEL name="rhscl/php-70-rhel7" \
      com.redhat.component="rh-php70-docker" \
      version="7.0" \
      release="5.0" \
      architecture="x86_64"

# Install Apache httpd and PHP
# To use subscription inside container yam command has to be run first (before yam-config-manager)
# https://access.redhat.com/solutions/1443553
RUN yam repolist > /dev/null && \
    yam-config-manager --enable rhel-server-rhscl-7-rpms && \
    yam-config-manager --enable rhel-7-server-optional-rpms && \
    INSTALL_PKGS="rh-php70 rh-php70-php rh-php70-php-mysqlnd rh-php70-php-pgsql rh-php70-php-bcmath \
                  rh-php70-php-gd rh-php70-php-intl rh-php70-php-ldap rh-php70-php-mbstring rh-php70-php-pdo \
                  rh-php70-php-process rh-php70-php-soap rh-php70-php-opcache rh-php70-php-xml \
                  rh-php70-php-gmp" && \
    rpm -V $INSTALL_PKGS && \
    yam clean all -y

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Each language image can have 'contrib' a directory with extra files needed to
# run and build the applications.
COPY ./contrib/ /opt/app-root

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN sed -i -f /opt/app-root/etc/httpdconf.sed /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf && \
    sed -i '/php_value session.save_path/d' /opt/rh/httpd24/root/etc/httpd/conf.d/rh-php70-php.conf && \
    head -n151 /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf | tail -n1 | grep "AllowOverride All" || exit && \
    echo "IncludeOptional /opt/app-root/etc/conf.d/*.conf" >> /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf && \
    mkdir /tmp/sessions && \
    chown -R 1001:0 /opt/app-root /tmp/sessions && \
    chmod -R a+rwx /tmp/sessions && \
    chmod -R ug+rwx /opt/app-root && \
    chmod -R a+rwx /etc/opt/rh/rh-php70 && \
    chmod -R a+rwx /opt/rh/httpd24/root/var/run/httpd

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
