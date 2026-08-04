## This file shows the partition configuration.

El disco virtual `/dev/vda`, de 25 GiB, se configuró manualmente mediante una tabla de particiones GPT y LVM. La siguiente captura muestra el diseño definido antes de confirmar la instalación:

![Storage Configuration](docs/storage-configuration.png)

En primer lugar, GPT divide `/dev/vda` en tres particiones físicas:

- Se ha creado una particion `/dev/vda1` de 1 MiB para BIOS boot utilizada por GRUB. Es necesaria porque la máquina virtual utiliza firmware BIOS junto con una tabla GPT. No contiene un sistema de archivos ni se monta en ningún directorio.

- En la particion `/dev/vda2` de 1 GiB se montada en `/boot`. Este directorio almacena el kernel, las imágenes `initramfs` y los archivos necesarios para el proceso de arranque.

- La partición `/dev/vda3` de aproximadamente 24 GiB, se configura como volumen físico de LVM para administrar de forma flexible el espacio restante.

La estructura física se valida con:

![Table of partitions](docs/fdisk-dev-vda.png)



Sobre `/dev/vda3` se creó el grupo de volúmenes `vg-ubuntu`. Dentro de él se definieron los siguientes volúmenes lógicos:

- Por un lado se crea un volumen lógico independiente para lv-root de 10 GiB, montado en /, contiene el sistema operativo, sus programas y la estructura principal de directorios. Se asignaron 10 GiB porque es suficiente para la instalación inicial de Ubuntu Server y las herramientas previstas, teniendo en cuenta que `/var` dispone de almacenamiento independiente.

- Por otro lado, el volumen lógico `lv-var` — 8 GiB, montado en `/var` contiene datos que pueden crecer continuamente, como registros del sistema, logs de servicios y cachés. Si `/var` comparte espacio con `/` y lo consume completamente, pueden fallar servicios, actualizaciones y otras operaciones esenciales. Su separación limita ese crecimiento y evita que ocupe directamente el sistema de archivos raíz.

- La partición`lv-swap` de 2 GiB se utiliza como espacio de intercambio cuando existe presión sobre la memoria RAM. 

- Por último se reservaron aproximadamente 4 GiB libres  dentro de `vg-ubuntu` para poder ampliar de forma dinámica `/` o `/var` mediante LVM.

A continuación muestra la configuración de LVM y la activación de swap se muestra en las siguientes captura:

![Show swap](docs/lvm-pvs-vgs-lvs.png)

La captura confirma la configuración de LVM: la partición `/dev/vda3` se utiliza como volumen físico del grupo `vg-ubuntu`, con una capacidad aproximada de 24 GiB. Dentro del grupo se crearon tres volúmenes lógicos: `lv-root` de 10 GiB, `lv-var` de 8 GiB y `lv-swap` de 2 GiB. Además, quedan aproximadamente 4 GiB libres para futuras ampliaciones.

![Show swap](docs/swap-&-free.png)

La captura confirma que el volumen de swap de 2 GiB está activo como `/dev/dm-2` y que, en ese momento, no estaba siendo utilizado. El comando `free -h` muestra además que la máquina dispone de aproximadamente 3,7 GiB de RAM, de los cuales solo se usan unos 410 MiB, por lo que el sistema mantiene suficiente memoria disponible y no necesita recurrir al espacio de intercambio.

















La siguiente captura muestra el diseño de almacenamiento definido durante la instalación de Ubuntu Server:

![Storage Configuration](docs/storage-configuration.png)


Primer lugar, GPT divide el disco /dev/vda en particiones físicas:
/dev/vda1: partición BIOS boot de 1 MiB.
/dev/vda2: partición ext4 montada en /boot.
/dev/vda3: partición utilizada como volumen físico de LVM.

Se ha creado una particion /dev/vda1 ...
También se creó una partición independiente de 1 GiB, formateada con ext4 y montada en /boot. Este sistema de archivos almacena el kernel, las imágenes initramfs y los archivos necesarios para el proceso de arranque.


Luego /dev/vda3 se utiliza LVM para proporcionar ....... y lo divide en volúmenes lógicos:

- Por un lado se crea un volumen lógico independiente para lv-root de 10 GiB, montado en /, 

- Por otro lado, se crea otro volumen lógico independiente para /var. Este directorio contiene datos que pueden crecer continuamente, como registros del sistema o logs de servicios. Si /var comparte el mismo sistema de archivos que / y consume todo el espacio disponible, pueden fallar servicios, actualizaciones y otras operaciones esenciales del sistema. Al separarlo, el crecimiento de estos datos queda limitado y se reduce el riesgo de que afecte directamente al sistema de archivos raíz.

- Por último se crea el volumn lógico lv-swap de 2 GiB, utilizado como espacio de intercambio






## References

The following chapters from LPIC-1 have been used for this phase.

- 102.1 Partitioning scheme design
- 102.2 Install a boot manager.
- 102.4 Debian package management.
- 102.6 Linux as a virtualized system.
- 104.1 Creating partitions and file systems
- 104.3 Mounting and /etc/fstab
