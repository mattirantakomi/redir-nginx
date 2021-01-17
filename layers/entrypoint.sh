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

echo "iptables -t nat -I PREROUTING 1 -i ${REDIRECT_FROM_INTERFACE} -p tcp -m tcp --dport ${REDIRECT_TO_PORT} -j ACCEPT"
iptables -t nat -I PREROUTING 1 -i ${REDIRECT_FROM_INTERFACE} -p tcp -m tcp --dport ${REDIRECT_TO_PORT} -j ACCEPT

/usr/bin/redir -s -n ":${REDIRECT_FROM_PORT}" "${REDIRECT_TO}:${REDIRECT_TO_PORT}" &

pid=$!
wait $!
