FROM ubuntu:18.04

RUN apt-get update && apt-get install -y nginx telnet \
    net-tools ncftp dnsutils iputils-ping traceroute iptables \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10000 user && useradd -m -d /ftp -g 10000 -u 10000 user

RUN rm -rf /etc/nginx/conf.d && mkdir /etc/nginx/conf.d

COPY layers/ /

ENTRYPOINT ["/entrypoint.sh"]
