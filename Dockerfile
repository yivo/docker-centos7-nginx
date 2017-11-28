FROM centos:7

RUN yum -y update \
 \
 # Install CentOS Linux Software Collections release file.
 && yum -y install centos-release-scl \
 \
 # Install build tools.
 && yum -y install which file devtoolset-7-make devtoolset-7-gcc devtoolset-7-gcc-c++ \
 \
 # Install NGINX dependencies.
 && yum -y install perl-devel perl-ExtUtils-Embed libxml2 libxslt-devel gd-devel geoip-devel \
 \
 # Download NGINX source code.
 && curl -sL http://nginx.org/download/nginx-1.13.7.tar.gz | tar xz -C /tmp \
 \
 # Download PCRE library source code.
 && curl -sL https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz | tar xz -C /tmp \
 \
 # Download zlib library source code.
 && curl -sL http://zlib.net/zlib-1.2.11.tar.gz | tar xz -C /tmp \
 \
 # Download OpenSSL library source code.
 && curl -sL https://www.openssl.org/source/openssl-1.1.0g.tar.gz | tar xz -C /tmp \
 \
 # Download GeoIP2 database.
 && mkdir /usr/local/share/GeoIP \
 && cd /usr/local/share/GeoIP \
 && curl -sL http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz | tar xz -C /tmp \
 && curl -sL http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz | tar xz -C /tmp \
 && curl -sL http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz | tar xz -C /tmp \
 && mv /tmp/GeoLite2-Country*/*.mmdb . \
 && mv /tmp/GeoLite2-City*/*.mmdb . \
 && mv /tmp/GeoLite2-ASN*/*.mmdb . \
 \
 # Build NGINX.
 && cd /tmp/nginx-1.13.7 \
 && scl enable devtoolset-7 " \
   ./configure \
     --user=nginx \
     --group=nginx \
     \
     --build=\"Built for CentOS 7 by Yaroslav Konoplov <eahome00@gmail.com>\" \
     \
     --with-pcre=/tmp/pcre-8.41 \
     --with-pcre-jit \
     \
     --with-zlib=/tmp/zlib-1.2.11 \
     \
     --with-threads \
     --with-file-aio \
     --with-compat \
     \
     --with-http_ssl_module \
     --with-openssl=/tmp/openssl-1.1.0g \
     --with-http_v2_module \
     --with-http_realip_module \
     --with-http_addition_module \
     --with-http_xslt_module=dynamic \
     --with-http_image_filter_module=dynamic \
     --with-http_geoip_module=dynamic \
     --with-http_sub_module \
     --with-http_dav_module \
     --with-http_flv_module \
     --with-http_mp4_module \
     --with-http_gunzip_module \
     --with-http_gzip_static_module \
     --with-http_auth_request_module \
     --with-http_random_index_module \
     --with-http_secure_link_module \
     --with-http_degradation_module \
     --with-http_slice_module \
     --with-http_stub_status_module \
     --with-http_perl_module=dynamic \
     \
     --with-mail=dynamic \
     --with-mail_ssl_module \
     \
     --with-stream=dynamic \
     --with-stream_ssl_module \
     --with-stream_realip_module \
     --with-stream_geoip_module=dynamic \
     --with-stream_ssl_preread_module \
     \
     --prefix=/etc/nginx \
     --sbin-path=/usr/sbin/nginx \
     --modules-path=/usr/lib64/nginx/modules \
     --conf-path=/etc/nginx/nginx.conf \
     --error-log-path=/var/log/nginx/error.log \
     --pid-path=/var/run/nginx.pid \
     --lock-path=/var/run/nginx.lock \
     \
     --http-log-path=/var/log/nginx/access.log \
     --http-client-body-temp-path=/var/cache/nginx/client_body_temp \
     --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
     --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
     --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
     --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
   " \
 && scl enable devtoolset-7 "make -j $(nproc)" \
 && scl enable devtoolset-7 "make install" \
 \
 # Create group "web" and user "nginx".
 && groupadd --system web \
 && useradd --system --create-home --home /var/cache/nginx --shell /sbin/nologin --no-log-init --user-group --groups web nginx \
 \
 # Symlink directory with modules so users can load dynamic modules by specifying path to it relative to /etc/nginx:
 #   load_module "modules/ngx_http_geoip_module.so";
 && ln -sf /usr/lib64/nginx/modules /etc/nginx/modules \
 \
 # Redirect NGINX logs to standard streams.
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 \
 # Check NGINX installation.
 && nginx -V \
 && nginx -t \
 \
 # Cleanup.
 && cd / \
 && rm -rf /tmp/nginx* /tmp/pcre* /tmp/zlib* /tmp/openssl* /tmp/Geo* \
 && yum clean all \
 && rm -rf /var/cache/yum
