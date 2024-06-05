#!/bin/bash
dnf remove -y git
dnf install -y nftables
dnf install -y bind bind-utils
dnf install -y chrony

useradd -c "Admin" Admin -U
echo "Admin:P@ssw0rd" | chpasswd

sed -i '/#Port 22/d' /etc/ssh/sshd_config
sed -i '17i\Port 2222' /etc/ssh/sshd_config
systemctl restart sshd

echo -e "table inet filter {\n\t\tchain input {\n\t\ttype filter hook input priority filter; policy accept;\n\t\tip saddr 3.3.3.2 tcp dport 2222 counter reject\n\t\tip saddr 4.4.4.0/30 tcp dport 2222 counter reject\t\t}\n}" > /etc/nftables/hq-srv.nft
sed -i '5i\include "/etc/nftables/hq-srv.nft"' /etc/sysconfig/nftables.conf

systemctl restart nftables
systemctl enable --now nftables
mkdir -p /var/lib/samba/bind-dns
touch /var/lib/samba/bind-dns/named.conf
grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf
sed -i "s/listen-on port 53 { 127.0.0.1; };/listen-on { any; };/" /etc/named.conf
sed -i "s/allow-query     { localhost; };/allow-query     { any; };/" /etc/named.conf
sed -i '18a\\tforward first;' /etc/named.conf
sed -i '19a\\tforwarders { 8.8.8.8; 77.88.4.4; };' /etc/named.conf
sed -i '20a\\ttkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";' /etc/named.conf
sed -i '52a\\tcategory lame-servers {null;};' /etc/named.conf
sed -i '22a\\tminimal-responses yes;' /etc/named.conf
echo -e 'zone "hq.work" {\n\ttype master;\n\tfile "/etc/zone/hq.db";\n};\nzone "branch.work" {\n\ttype master;\n\tfile "/etc/zone/branch.db";\n};\nzone "100.16.172.in-addr.arpa" {\n\ttype master;\n\tfile "/etc/zone/172.db";\n};\nzone "100.168.192.in-addr.arpa" {\n\ttype master;\n\tfile "/etc/zone/192.db";\n};' >> /etc/named.conf
mkdir /etc/zone
echo -e "\$TTL\t1D\n@\tIN\tSOA\thq.work root.hq.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\thq.work.\n\tIN\tA\t127.0.0.0\nhq-r\tIN\tA\t172.16.100.1\nhq-srv\tIN\tA\t172.16.100.2\n_kerberos._udp.hq.work.\t86400\tIN\tSRV\t0\t100\t88\thq-srv.hq.work.\n_kerberos._tcp.hq.work.\t86400\tIN\tSRV\t0\t100\t88\thq-srv.hq.work.\n_ldap._tcp.hq.work.\t86400\tIN\tSRV\t0\t100\t389\thq-srv.hq.work.\n_ldap._udp.hq.work.\t86400\tIN\tSRV\t0\t100\t389\thq-srv.hq.work." >/etc/zone/hq.db
echo -e "\$TTL\t1D\n@\tIN\tSOA\tbranch.work root.branch.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\tbranch.work.\n\tIN\tA\t127.0.0.0\nbr-r\tIN\tA\t192.168.100.1\nbr-srv\tIN\tA\t192.168.100.10" >/etc/zone/branch.db
echo -e "\$TTL\t1D\n@\tIN\tSOA\thq.work root.hq.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\thq.work.\n1\tIN\tPTR\thq-r.hq.work.\n2\tIN\tPTR\thq-srv.hq.work." >/etc/zone/172.db
echo -e "\$TTL\t1D\n@\tIN\tSOA\tbranch.work root.branch.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\tbranch.work.\n1\tIN\tPTR\tbr-r.branch.work." >/etc/zone/192.db
chown root:named /etc/zone/{hq,branch,172,192}.db

systemctl enable --now named
systemctl restart named
systemctl restart NetworkManager

timedatectl set-timezone Europe/Moscow
sed -i '3s/^/#/' /etc/chrony.conf
sed -i '4s/^/#/' /etc/chrony.conf
sed -i '5s/^/#/' /etc/chrony.conf
sed -i '6s/^/#/' /etc/chrony.conf
sed -i '7a\server 172.16.100.1 iburst prefer' /etc/chrony.conf

systemctl enable --now chronyd
systemctl restart chronyd
chronyc sources

systemctl stop named
echo "HOSTNAME=hq-srv.hq.work" >> /etc/sysconfig/network
domainname hq.work

rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol

rm -f /var/lib/krb5kdc
mkdir -p /var/lib/krb5kdc
kdb5_util create -s

samba-tool domain provision --realm=hq.work --domain=hq --adminpass='P@ssw0rd' --dns-backend=BIND9_DLZ --server-role=dc --use-rfc2307

systemctl enable --now samba
systemctl enable --now named

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

sed -i "s/dns_lookup_kdc = false/dns_lookup_kdc = true/" /etc/krb5.conf
sed -i '9a\\tkdc_ports = 88' /etc/krb5.conf
sed -i '10a\\tkdc_tcp_ports = 88' /etc/krb5.conf
sed -i '11a\\tadmin_server = HQ-SRV.hq.work' /etc/krb5.conf
sed -i '12a\\tkdc = HQ-SRV.hq.work' /etc/krb5.conf
sed -i '13a\\tdatabase_name = /var/lib/krb5kdc/principal' /etc/krb5.conf
sed -i '16a\\t.HQ-SRV = HQ.WORK' /etc/krb5.conf
sed -i '17a\\thq-srv = HQ.WORK' /etc/krb5.conf
sed -i '18a\\t.hq-srv = HQ.WORK' /etc/krb5.conf

host -t SRV _ldap._tcp




samba-tool domain info 127.0.0.1

hostnamectl set-hostname HQ-SRV.hq.work; exec bash







