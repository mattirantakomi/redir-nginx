#!/usr/bin/env bash

set -eo pipefail

_term() {
  echo "TERM"
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

echo "Redirecting port ${REDIRECT_FROM_PORT} to ${REDIRECT_TO}.${SUBDOMAIN} (${REDIRECT_TO_IP}) port ${REDIRECT_TO_PORT}"
/usr/bin/redir -s -n ":${REDIRECT_FROM_PORT}" "${REDIRECT_TO}:${REDIRECT_TO_PORT}" --transproxy &
echo

pid=$!
wait $!



;; ANSWER SECTION:
ingress-nginx-controller.ingress-nginx.svc.cluster.local. 5 IN A 10.43.24.7

;; Query time: 1 msec
;; SERVER: 10.43.0.10#53(10.43.0.10)
;; WHEN: Sun Jan 17 09:24:11 UTC 2021
;; MSG SIZE  rcvd: 169

root@node3:/# dig ingress-nginx-controller.${SUBDOMAIN} +short
10.43.24.7

