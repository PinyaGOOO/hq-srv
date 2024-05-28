#!/bin/bash
dnf remove -y git
dnf install -y nftables
dnf install -y bind bind-utils

useradd -c "Admin" Admin -U
echo "Admin:P@ssw0rd" | chpasswd

sed -i '/#Port 22/d' /etc/ssh/sshd_config
sed -i '17i\Port 2222' /etc/ssh/sshd_config
systemctl restart sshd

echo -e "table inet filter {\n\t\tchain input {\n\t\ttype filter hook input priority filter; policy accept;\n\t\tip saddr 3.3.3.2 tcp dport 2222 counter reject\n\t\tip saddr 4.4.4.0/30 tcp dport 2222 counter reject\t\t}\n}" > /etc/nftables/hq-srv.nft
sed -i '5i\include "/etc/nftables/hq-srv.nft"' /etc/sysconfig/nftables.conf

systemctl restart nftables
systemctl enable --now nftables
sed -i "s/listen-on port 53 { 127.0.0.1; };/listen-on { any; };/" /etc/named.conf
sed -i "s/allow-query     { localhost; };/allow-query     { any; };/" /etc/named.conf
sed -i '20a//tforward first;' /etc/named.conf
sed -i '21a//tforwarders { 8.8.8.8; 77.88.4.4; };' /etc/named.conf

hostnamectl set-hostname HQ-SRV; exec bash







