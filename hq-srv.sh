#!/bin/bash
dnf remove -y git
dnf install -y nftables

useradd -c "Admin" Admin -U
echo "Admin:P@ssw0rd" | chpasswd

sed -i '/#Port 22/d' /etc/ssh/sshd_config
sed -i '17i\Port 2222' /etc/ssh/sshd_config
systemctl restart sshd

echo -e "table inet filter {\n\t\tchain input {\n\t\ttype filter hook input priority filter; policy accept;\n\t\tip saddr 3.3.3.2 tcp dport 2222 counter reject\n\t\tip saddr 4.4.4.0/30 tcp dport 2222 counter reject\n\t\tip6 saddr 2024:ab:cd:3::/64 tcp dport 2222 counter reject\n\t\tip6 saddr 2024:ab:cd:4::/64 tcp dport 2222 counter reject\n\t\t}\n}" > /etc/nftables/hq-srv.nft
sed -i '5i\include "/etc/nftables/hq-srv.nft"' /etc/sysconfig/nftables.conf

systemctl restart nftables
systemctl enable --now nftables

hostnamectl set-hostname HQ-SRV; exec bash







