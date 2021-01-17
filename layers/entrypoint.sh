#!/usr/bin/env bash

set -eo pipefail

_term() {
  echo "TERM"
  OLDIFS=$IFS
  IFS=','
  for RULE in $(iptables-save | grep PREROUTING | grep "${REDIRECT_FROM_INTERFACE}" | grep "\-\-dport ${REDIRECT_TO_PORT}" | sed -e "s/^-A/iptables -t nat -D/g"); do
    echo "$RULE"
    eval "$RULE"
  done
IFS=$OLDIFS
  kill -9 $pid
  echo "killed $pid"
  exit
}
trap _term TERM

OLDIFS=$IFS
IFS=','
for RULE in $(iptables-save | grep PREROUTING | grep "${REDIRECT_FROM_INTERFACE}" | grep "\-\-dport ${REDIRECT_TO_PORT}" | sed -e "s/^-A/iptables -t nat -D/g"); do
  echo "$RULE"
  eval "$RULE"
done
IFS=$OLDIFS

REDIRECT_FROM_INTERFACE_IP="$(ifconfig ${REDIRECT_FROM_INTERFACE} | grep 'inet ' | awk '{ print $2 }')"
SUBDOMAIN=$(grep search /etc/resolv.conf | awk '{ print $2 }')
REDIRECT_TO_IP=$(dig ingress-nginx-controller.${SUBDOMAIN} +short)

echo "iptables -t nat -I PREROUTING 1 -i ${REDIRECT_FROM_INTERFACE} -p tcp -m tcp --dport ${REDIRECT_TO_PORT} -j ACCEPT"
iptables -t nat -I PREROUTING 1 -i ${REDIRECT_FROM_INTERFACE} -p tcp -m tcp --dport ${REDIRECT_TO_PORT} -j ACCEPT
echo

echo "Redirect from interface ${REDIRECT_FROM_INTERFACE} public IP is ${REDIRECT_FROM_INTERFACE_IP} on node ${NODE_HOSTNAME}"
echo

echo "echo 1 > /proc/sys/net/ipv4/conf/${REDIRECT_FROM_INTERFACE}/route_localnet"
echo 1 > /proc/sys/net/ipv4/conf/${REDIRECT_FROM_INTERFACE}/route_localnet

echo "stream {" >> /etc/nginx/conf.d/proxy.conf
echo "  server {" >> /etc/nginx/conf.d/proxy.conf
echo "    listen ${REDIRECT_FROM_PORT};" >> /etc/nginx/conf.d/proxy.conf
echo "    proxy_pass 127.0.0.1:${REDIRECT_TO_PORT};" >> /etc/nginx/conf.d/proxy.conf
echo "    proxy_bind 127.0.0.1:${REDIRECT_TO_PORT} transparent;" >> /etc/nginx/conf.d/proxy.conf
echo "  }" >> /etc/nginx/conf.d/proxy.conf
echo "}" >> /etc/nginx/conf.d/proxy.conf

echo "Starting nginx"
/usr/sbin/nginx &

pid=$!
wait $!
