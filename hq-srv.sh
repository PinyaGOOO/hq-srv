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
sed -i '18a\\tforward first;' /etc/named.conf
sed -i '19a\\tforwarders { 8.8.8.8; 77.88.4.4; };' /etc/named.conf
echo -e 'zone "hq.work" {\n\ttype master;\n\tfile "hq.db";\n};\nzone "branch.work" {\n\ttype master;\n\tfile "branch.db";\n};\nzone "100.16.172.in-addr.arpa" {\n\ttype master;\n\tfile "172.db";\n};\nzone "100.168.192.in-addr.arpa" {\n\ttype master;\n\tfile "192.db";\n};' >> /etc/named.conf
mkdir /etc/zone
echo -e "$TTL\t1D\n@\tIN\tSOA\thq.work root.hq.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\thq.work.\n\tIN\tA\t127.0.0.0\nhq-r\tIN\tA\t172.16.100.1\nhq-srv\tIN\tA\t172.16.100.2" >/etc/zone/hq.db
echo -e "$TTL\t1D\n@\tIN\tSOA\tbranch.work root.branch.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\tbranch.work.\n\tIN\tA\t127.0.0.0\nbr-r\tIN\tA\t192.168.100.1\nbr-srv\tIN\tA\t192.168.100.10" >/etc/zone/branch.db
echo -e "$TTL\t1D\n@\tIN\tSOA\thq.work root.hq.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\thq.work.\n1\tIN\tPTR\thq-r.hq.work.\n2\tIN\tPTR\thq-srv.hq.work." >/etc/zone/172.db
echo -e "$TTL\t1D\n@\tIN\tSOA\tbranch.work root.branch.work. (\n\t\t\t\t2024021400\t; serial\n\t\t\t\t12H\t\t; refresh\n\t\t\t\t1H\t\t; retry\n\t\t\t\t1W\t\t; expire\n\t\t\t\t1H\t\t; ncache\n\t\t\t)\n\tIN\tNS\tbranch.work.\n1\tIN\tPTR\tbr-r.branch.work." >/etc/zone/192.db
chown root:named /etc/bind/zone/ {hq,branch,172,192}.db

hostnamectl set-hostname HQ-SRV; exec bash







