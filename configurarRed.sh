#!/bin/bash

# Script para establecer la configuración de red de las máquinas virtuales utilizadas en las
# prácticas de la asignatura Redes y Seguridad 2 de la Universidad Complutense de Madrid.

# MIT License

# Copyright (c) 2021 Mario Román Dono

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

salirTrasError () {
	echo "Fallo al ejecutar el comando. ¿Iniciaste el script con sudo?"
	exit
}

escribirIPenArchivo() {
	echo "Interfaz: ${1}"
	echo "Introduce la IP: "
	read ip
	echo "Introduce la máscara de subred (presiona Enter si quieres que sea 255.255.255.0): "
	read mascara
	if [ -z "$mascara"]; then
		mascara="255.255.255.0"
	fi
	comandoIP="\nauto ${interfaz}\niface ${interfaz} inet static\naddress ${ip}\nnetmask ${mascara}\n"
	echo -en $comandoIP >> /etc/network/interfaces || salirTrasError
	echo "Configuración añadida al fichero /etc/network/interfaces"
}

configurarIP() {
	if [ "$tipomv" = "Router" ] ; then
		interfaz="enp0s8"
		escribirIPenArchivo $interfaz

		interfaz="enp0s9"
		escribirIPenArchivo $interfaz
	else
		if [ "$so" = "Kali" ] ; then
			interfaz="eth1"
		else 
			interfaz="enp0s8"
		fi
		escribirIPenArchivo $interfaz
	fi
	# Pasos 2 y 3
	echo "Ejecutando /etc/init.d/networking reload"
	/etc/init.d/networking reload || salirTrasError
	echo "Ejecutando /etc/init.d/networking restart"
	/etc/init.d/networking restart || salirTrasError
}

configurarRuta() {
	echo "Selecciona si quieres configurar una ruta por defecto o a una red determinada"
	select tipoRuta in "Por defecto" "Red específica";
	do
		case $tipoRuta in
			"Por defecto" ) break;;
			"Red específica" ) break;;
			* ) echo "Opción incorrecta"
		esac
	done
	echo "Selecciona la puerta de enlace o gateway:"
	read gateway
	if [ "$tipoRuta" = "Red específica" ]; then
		echo "Escribe la red de destino (con notación CIDR):"
		read redDestino
		echo "Configurando la ruta de enrutamiento..."
		route add -net ${redDestino} gw ${gateway} || salirTrasError
		echo "Configurada"
	else
		echo "Configurando la ruta de enrutamiento..."
		route add default gw ${gateway} || salirTrasError
		echo "Configurada"	
	fi
}

configurarIptables() {
	echo "Configurando las reglas de Iptables relativas al tráfico DNS..."
	if [ "$tipomv" = "Router" ] ; then
		iptables -A FORWARD -p udp --dport 53 -j DROP || salirTrasError
	fi
	iptables -A OUTPUT -p udp --dport 53 -j DROP || salirTrasError
	echo "Reglas iptables añadidas"
}

# Comienzo del script
# Parámetros previos

PS3="Introduce un número: "
echo "Configuración de red para la máquina virtual de Redes y Seguridad"

echo "Selecciona el sistema operativo:"
select so in "Kali" "Debian";
do
	case $so in
		Kali ) break;;
		Debian ) break;;
		* ) echo "Opción incorrecta"
	esac
done

echo "Selecciona si quieres configurar un host o un router:"
select tipomv in "Host" "Router";
do
	case $tipomv in
		Host ) break;;
		Router ) break;;
		* ) echo "Opción incorrecta"
	esac
done

# Paso 1: Si es necesario, modificar el archivo /etc/network/interfaces y reiniciar el servicio networking 
echo "¿Quieres configurar la dirección IP?"
select ipconf in "Si" "No";
do
	case $ipconf in
		Si ) configurarIP
			break;;
		No ) break;;
		* ) echo "Opción incorrecta"
	esac
done

# Paso 4: Desactivar el adaptador NAT
if [ "$so" = "Kali" ] ; then
	interfaz="eth0"
else 
	interfaz="enp0s3"
fi
echo "Desactivando el adaptador NAT: ${interfaz}..."
ifconfig ${interfaz} down || salirTrasError
echo "Desactivado"

# Paso 5: Desactivar el network-manager si el SO es Debian
if [ "$so" = "Debian" ] ; then
	echo "Desactivando network-manager..."
	service network-manager stop || salirTrasError
	echo "Desactivado"
fi

# Paso 6: Configurar las rutas de encaminamiento si son necesarias
echo "¿Quieres añadir una ruta de encaminamiento?"
select opRuta in "Si" "No";
do
	case $opRuta in
		Si ) configurarRuta 
			break ;;
		No ) break;;
		* ) echo "Opción incorrecta"
	esac
done

# Paso 7: Si se trata de un router, activar el reenvío de paquetes
if [ "$tipomv" = "Router" ] ; then
	echo "Activando el reenvío de paquetes..."
	sysctl -w net.ipv4.ip_forward=1 || salirTrasError
	echo "Activado"
fi

# Paso 8: Preguntar si se desea configurar las reglas Iptables relativas al DNS
echo "¿Quieres añadir las reglas de Iptables para restringir el tráfico DNS?"
select opDNS in "Si" "No";
do
	case $opDNS in
		Si ) configurarIptables 
			break ;;
		No ) break;;
		* ) echo "Opción incorrecta"
	esac
done

# Fin del script
echo "Todo listo!"
