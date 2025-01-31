#!/bin/bash

# Define as políticas padrão para INPUT, FORWARD e OUTPUT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Limpa todas as regras e cadeias customizadas
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# Repete as operações para garantir que todas as regras são limpas
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# Faz o mesmo para ip6tables
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -F
ip6tables -X

# Salva as regras do iptables
sudo iptables-save > /etc/iptables/rules.v4

# Confirma que as regras foram salvas e aplicadas
echo "iptables e ip6tables configurados e salvos em /etc/iptables/rules.v4."
