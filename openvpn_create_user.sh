#!/bin/sh

{% raw %}

if [ $# -ne 1 ]
then
  echo "Usage: $0 <CLIENT_KEY_NAME>"
  exit
fi

DIR=openvpn
if ! test -d $DIR; then mkdir $DIR; fi

KEY_NAME=$1
NAMESPACE=openvpn
HELM_RELEASE=openvpn
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_NAME=$(kubectl get svc -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_IP=$(kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o go-template='{{range $k, $v := (index .status.loadBalancer.ingress 0)}}{{$v}}{{end}}')
kubectl -n "$NAMESPACE" exec -it "$POD_NAME" /etc/openvpn/setup/newClientCert.sh "$KEY_NAME" "$SERVICE_IP"
kubectl -n "$NAMESPACE" exec -it "$POD_NAME" cat "/etc/openvpn/certs/pki/$KEY_NAME.ovpn" > $DIR/"$KEY_NAME.ovpn"
DNS=$(kubectl -n "$NAMESPACE" exec -it "$POD_NAME" cat "/etc/resolv.conf" | grep nameserver | cut -d " " -f 2)
DOMAIN=$(kubectl -n "$NAMESPACE" exec -it "$POD_NAME" cat "/etc/resolv.conf" | grep search | cut -d " " -f 4)
echo "\nscript-security 2\ndhcp-option DNS $DNS\ndhcp-option DOMAIN $DOMAIN" >> $DIR/"$KEY_NAME.ovpn"

{% endraw %}
