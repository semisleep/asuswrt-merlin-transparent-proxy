#!/bin/sh

proxy_is_disable='/tmp/proxy_is_disable'

if [ "$1" == 'disable' ] || [ -x /opt/etc/iptables.sh ]; then
    echo 'Disable proxy ...'

    # clean iptables rule start
    ipset_protocal_version=$(ipset -v |grep -o 'version.*[0-9]' |head -n1 |cut -d' ' -f2)

    if [ "$ipset_protocal_version" == 6 ]; then
        alias iptables='/usr/sbin/iptables'
    else
        alias iptables='/opt/sbin/iptables'
    fi

    while iptables -t nat -C PREROUTING -p tcp -j SHADOWSOCKS_TCP 2>/dev/null; do
        iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS_TCP
    done

    iptables -t nat -F SHADOWSOCKS_TCP 2>/dev/null          # flush
    iptables -t nat -X SHADOWSOCKS_TCP 2>/dev/null          # --delete-chain

    while iptables -t mangle -C PREROUTING -p udp -j SHADOWSOCKS_UDP 2>/dev/null; do
        iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS_UDP
    done

    iptables -t mangle -F SHADOWSOCKS_UDP 2>/dev/null
    iptables -t mangle -X SHADOWSOCKS_UDP 2>/dev/null

    iptables -t mangle -F SHADOWSOCKS_MARK 2>/dev/null
    iptables -t mangle -X SHADOWSOCKS_MARK 2>/dev/null
    # clean iptables rule end

    chmod -x /opt/etc/iptables.sh
    chmod -x /opt/etc/patch_router

    sed -i "s#conf-dir=/opt/etc/dnsmasq.d/,\*\.conf#\# &#" /etc/dnsmasq.conf
    /opt/etc/restart_dnsmasq
    echo 'Proxy is disabled.'
    touch $proxy_is_disable
else
    echo 'Enable proxy ...'
    chmod +x /opt/etc/iptables.sh
    chmod +x /opt/etc/patch_router && /opt/etc/patch_router
    echo 'Proxy is enabled.'
    rm $proxy_is_disable
fi

# iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS
