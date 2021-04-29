#!/bin/bash

# Script para establecer la configuración de red de las máquinas virtuales utilizadas en las
# prácticas de la asignatura Redes y Seguridad 2 de la Universidad Complutense de Madrid.
# Desarrollado por Mario Román Dono

salirTrasError () {
	echo "Fallo al ejecutar el comando. ¿Iniciaste el script con sudo?"
	exit
}

configurarIP() {
if [ "$tipomv" = "Router" ] ; then
	interfaz="enp0s8"
	echo "Interfaz: ${interfaz}"
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

	interfaz="enp0s9"
	echo "Interfaz: ${interfaz}"
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
else
	if [ "$so" = "Kali" ] ; then
		interfaz="eth1"
	else 
		interfaz="enp0s8"
	fi
	echo "Interfaz: ${interfaz}"
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

# Paso 7
echo "Configurando las reglas de Iptables relativas al tráfico DNS..."
if [ "$tipomv" = "Router" ] ; then
	iptables -A FORWARD -p udp --dport 53 -j DROP || salirTrasError
fi
iptables -A OUTPUT -p udp --dport 53 -j DROP || salirTrasError
echo "Reglas iptables añadidas"

# Fin del script
echo "Todo listo!"