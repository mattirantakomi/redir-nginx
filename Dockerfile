FROM ubuntu:18.04

RUN apt-get update && apt-get install -y redir telnet \
    net-tools ncftp dnsutils iputils-ping traceroute iptables \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10000 user && useradd -m -d /ftp -g 10000 -u 10000 user

COPY layers/ /

ENTRYPOINT ["/entrypoint.sh"]
