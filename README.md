# Automate RyS

El propósito de este repositorio es facilitar una serie de herramientas, scripts y archivos para automatizar el despliegue y configuración de las máquinas virtuales de las prácticas de la asignatura Redes y Seguridad II, perteneciente al Grado en Ingeniería Informática de la Universidad Complutense de Madrid.

Esta necesidad surge de que, en todas las prácticas, se debe desplegar una infraestructura de máquinas virtuales con casi las mismas características, perdiendo un tiempo en una tarea repetitiva que puede ser automatizada para así dedicar más tiempo al contenido de la práctica en sí.

Esta tarea de automatización se ha llevado a cabo con la herramienta [Vagrant](https://www.vagrantup.com/). Existen diez carpetas en el repositorio, una por cada práctica, y cada una de ellas contiene un Vagrantfile que describe la arquitectura virtual utilizada para la práctica. Para desplegarla, solamente hay que ejecutar `vagrant up`. Las boxes utilizadas en las prácticas se pueden encontrar [aquí](https://drive.google.com/drive/folders/1z1nq-RbXiokPNQfdvKvDrL3-QvlYQfO7?usp=sharing).

El repositorio también contiene otro archivo, `configurarRed.sh`, un script interactivo de Bash que reduce el tiempo necesario a la hora de modificar la configuración de red de las máquinas virtuales.

Todos los scripts y archivos de este repositorio pueden ser utilizados por cualquier persona libremente con cualquier propósito. Asimismo, cualquier aporte es bienvenido.

## TODO

- Crear un manual de usuario / wiki que describa los pasos que se deben seguir para crear la arquitectura de cada práctica.
- Modificar los scripts de provisión en los Vagrantfile, reemplazando comandos obsoletos como `route` o `ipconfig` por los correspondientes de la suite `ip`.
