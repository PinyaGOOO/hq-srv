#!/bin/bash

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

sed -i "s/dns_lookup_kdc = false/dns_lookup_kdc = true/" /etc/krb5.conf
sed -i "s/dns_lookup_realm = false/dns_lookup_realm = true/" /etc/krb5.conf
sed -i '8a\\tkdc_ports = 88' /etc/krb5.conf
sed -i '9a\\tkdc_tcp_ports = 88' /etc/krb5.conf
sed -i '10a\\tadmin_server = HQ-SRV.hq.work' /etc/krb5.conf
sed -i '11a\\tkdc = HQ-SRV.hq.work' /etc/krb5.conf
sed -i '12a\\tdatabase_name = /var/kerberos/krb5kdc/principal' /etc/krb5.conf
sed -i '16a\\t.HQ-SRV = HQ.WORK' /etc/krb5.conf
sed -i '17a\\thq-srv = HQ.WORK' /etc/krb5.conf
sed -i '18a\\t.hq-srv = HQ.WORK' /etc/krb5.conf

kdb5_util create -s







