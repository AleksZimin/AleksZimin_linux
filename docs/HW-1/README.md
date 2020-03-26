### [Вернуться в корень репо](/../../)

# Main task

## Предварительные действия

### [Подготовил виртуалку в GCP с включенной вложенной виртуализацией](../common/GCP.MD#create-vm-with-enabled-nested-virtualisation)

### [Установил утилиты HashiCorp (Vagrant и Packer) на виртуалку в GCP](../common/INSTALLATION.MD#hashicorp-utils)

### [Установил VirtualBox на виртуалку в GCP](../common/INSTALLATION.MD#virtualbox)

### [Установил qemu-kvm](../common/INSTALLATION.MD#qemu-kvm)

### [Установил провайдер vagrant-libvirt для Vagrant на виртуалку в GCP](../common/INSTALLATION.MD#install-provider-vagrant-libvirt-for-vagrant)

### Подготовил репозиторий (предварительно создал свой репо для выполнения ДЗ на github)

- Подготовил структуру каталогов и скопировал изначальные файлы для ДЗ из репо преподавателя

```bash
mkdir -p ~/REPO/ && cd ~/REPO/
git clone https://github.com/dmitry-lyutenko/manual_kernel_update.git
git clone https://github.com/AleksZimin/AleksZimin_linux.git
cd AleksZimin_linux
git checkout -b linux-kernel
mkdir -p {docs/HW-1,linux-kernel}
touch docs/HW-1/README.md
cp -R ../manual_kernel_update/{packer,Vagrantfile} linux-kernel/
mkdir -p linux-kernel/packer/packer_artifact
```

- Настроил гит

```bash
git config --global user.email "realzav@gmail.com"
git config --global user.name "AleksZimin"
```

- Добавил файл .gitignore в корень репо. Исключил папки .vagrant/ packer_cache/ packer_artifact/

- Закоммитил изменения и запушил их в удаленный репозиторий

```bash
git add . && git commit -m "HW-1. Initial commit"
git push --set-upstream origin linux-kernel
```

## Основные действия

### Запустил виртуальную машину

- Перешел в директорию с Vagrantfile, параметризировал в нем провайдер, добавил настройки VRDE для Vbox и запустил виртуалку в kvm (для запуска в VirtualBox использовать MY_PROVIDER='virtualbox')

```bash
cd ~/REPO/AleksZimin_linux/linux-kernel/
vim Vagrantfile
MY_PROVIDER='libvirt' vagrant up
```

- Зашел в созданную виртуалку по ssh

```bash
vagrant ssh
```

### Установил новое ядро

- Проверил текущую версию

```bash
[vagrant@kernel-update ~]$ uname -r
3.10.0-957.12.2.el7.x86_64
```

- Подключил репозиторий с новыми версиями ядра

```bash
sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

- Установил последнее ядро kernel-ml (Существуют версии kernel-ml и kernel-lt. Первая является наиболее свежей стабильной версией, вторая это стабильная версия с длительной поддержкой, но менее свежая, чем первая)

```bash
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```

### Проверил работу нового ядра

- Узнал номер порта VNC (по-умолчанию 5900)

```bash
sudo virsh dumpxml $(sudo virsh list | grep kernel-update | cut -d ' ' -f 2) | grep vnc
```

- Подключился к виртуалке по VNC (подключался со своей машины и использовал port-forwarding, т.к. по-умолчанию VNC работает на интерфейсе 127.0.0.1)

- Перезагрузкил виртуалку kernel-update (логин/пароль vagrant/vagrant)

```bash
sudo shutdown -r now
```

- При загрузке выбрал новую версию ядра

- Подключился к виртуалке по ssh с хостовой системы

```bash
cd ~/REPO/AleksZimin_linux/linux-kernel/ && vagrant ssh
```

- Проверил версию ядра

```bash
[vagrant@kernel-update ~]$ uname -r
5.5.9-1.el7.elrepo.x86_64
```

- Далее необходимо проверить работоспособность системы

### Назначил новое ядро ядром по-умолчанию

- Обновил конфигурацию загрузчика

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

- Выбрал загрузку с новым ядром по-умолчанию

```bash
sudo grub2-set-default 0
```

- Перезагрузил виртуалку, снова зашел на нее по ssh

```bash
sudo shutdown -r now
cd ~/REPO/AleksZimin_linux/linux-kernel/ && vagrant ssh
```

- Проверил версию ядра

```bash
[vagrant@kernel-update ~]$ uname -r
5.5.9-1.el7.elrepo.x86_64
```

### Создал образ системы с ядром новой версии

- Перешел в директорию packer

```bash
cd ~/REPO/AleksZimin_linux/linux-kernel/packer
```

- На основе файла centos.json создал файлы centos_qemu.json и centos_virtualbox.json

```bash
cp centos.json centos_virtualbox.json && mv centos.json centos_qemu.json
```

- Создал образ для kvm и VirtualBox (для VirtualBox изменил ssh таймаут, т.к. в GCP вложенная виртуалка на Virtualbox работает намного медленнее, чем виртуалка на kvm)

```bash
packer build centos_qemu.json
packer build centos_virtualbox.json
```

- Импортировал созданные образы в Vagrant

```bash
cd ~/REPO/AleksZimin_linux/linux-kernel
MY_PROVIDER='libvirt' vagrant box add --name centos-7-5 packer/packer_artifact/kvm-centos-7.7.1908-kernel-5-x86_64-Minimal.box

MY_PROVIDER='virtualbox' vagrant box add --name centos-7-5 packer/packer_artifact/virtualbox-centos-7.7.1908-kernel-5-x86_64-Minimal.box
```

- Проверил список имеющихся образов

```bash
vagrant box list
  centos-7-5 (libvirt, 0)
  centos-7-5 (virtualbox, 0)
```

- Параметризировал имя box в Vagrantfile и запустил виртуалку из нашего образа

```bash
MY_PROVIDER='virtualbox' MY_BOX='centos-7-5' vagrant up
```

- Зашел на виртуальную машину,  проверил версию ядра и проверил работу второй стадии provisioning

```bash
MY_PROVIDER='virtualbox' vagrant ssh

[vagrant@kernel-update ~]$ uname -r
  5.5.9-1.el7.elrepo.x86_64

[vagrant@kernel-update ~]$ sudo grep "Hi from" /boot/grub2/grub.cfg
  ###   Hi from secone stage
```

### Загрузил полученный образ в Vagrant Cloud

- Создал аккаунт в <https://app.vagrantup.com/>

- Залогинился в Vagrant Cloud в cli

```bash
vagrant cloud auth login
  Vagrant Cloud username or email: <user_email>
  Password (will be hidden):
  Token description (Defaults to "Vagrant login from DS-WS"):
  You are now logged in.
```

- Опубликовал полученный бокс

```bash
USERNAME=realzav
vagrant cloud publish --release $USERNAME/centos-7-5 1.0 virtualbox \
        packer/packer_artifact/virtualbox-centos-7.7.1908-kernel-5-x86_64-Minimal.box
```

# Additional tasks

## Задание со *: собрал ядро из исходников

### Собрал ядро вручную

- Зашел на виртуалку

```bash
cd /home/zav/REPO/AleksZimin_linux/linux-kernel
MY_PROVIDER='virtualbox' vagrant up
vagrant ssh
```

- Обновил Centos

```bash
sudo yum clean all && sudo yum update -y
sudo shutdown -r now
```

- Установил необходимые пакеты

```bash
sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 perl
```

- Установил gpg ключи основных разработчиков ядра и добавил их в доверенные

```bash
gpg --keyserver pgp.mit.edu --recv {ABAF11C65A2970B130ABE3C479BE3E4300411886,\
647F28654894E3BD457199BE38DBBDC86092693E,\
E27E5D8A3403A2EF66873BBCDEA66FF797772CDC,\
AC2B29BD34A6AFDDB3F68F35E7BFC8EC95861109}

echo -e "5\ny\n" | gpg --command-fd 0 --edit-key {ABAF11C65A2970B130ABE3C479BE3E4300411886,\
647F28654894E3BD457199BE38DBBDC86092693E,\
E27E5D8A3403A2EF66873BBCDEA66FF797772CDC,\
AC2B29BD34A6AFDDB3F68F35E7BFC8EC95861109} trust
```

- Скачал исходники нужной версии и файл с ЭЦП

```bash
KERNEL_VER=4.19.109
MAJOR_VER=$(echo $KERNEL_VER | cut -d '.' -f 1)
cd /usr/src/
sudo curl --remote-name-all https://cdn.kernel.org/pub/linux/kernel/v${MAJOR_VER}.x/linux-${KERNEL_VER}.tar.{sign,xz}
```

- Распаковал xz архив в stdout, из stout с помощью tee параллельно распаковал tar архив и проверил подлинность tar архива, используя файл подписи

```bash
xz -cd linux-${KERNEL_VER}.tar.xz | tee >(sudo tar -x) | gpg2 --verify linux-${KERNEL_VER}.tar.sign -
```

- Скопировал текущую конфигурацию ядра в каталог сборки. Данный конфиг будет взят за основу при конфигурировании новой сборки

```bash
cd linux-${KERNEL_VER}
sudo make mrproper
sudo cp -v /boot/config-$(uname -r) .config
```

- Далее можно сконфигурировать сборку с помощью GUI (опционально. Если пропустить этот шаг, то все недостающие опции будут запрошены перед сборкой)

```bash
# sudo make menuconfig
```

- Так же можно сконфигурировать сборку, используя конфиг текущего ядра и подставляя недостающие значения автоматически (они будут выставлены в значение по-умолчанию)

```bash
sudo make olddefconfig
```

- Включим сжатие модулей с помощью xz

```bash
sudo sed -i '/^.*CONFIG_MODULE_COMPRESS.*$/d' .config


sudo bash -c "echo "CONFIG_MODULE_COMPRESS=y">>.config"
sudo bash -c "echo "CONFIG_MODULE_COMPRESS_XZ=y">>.config"
sudo bash -c "echo '# CONFIG_MODULE_COMPRESS_GZIP is not set'>>.config"
```

- Для сборки минимально необходимого числа модулей используем target localmodconfig (предварительно должен быть скопирован текущий конфиг и выполнена сборка с target olddefconfig), а так же вручную включим несколько необходимых модулей

```bash
echo "n" | sudo make localmodconfig

sudo bash -c "echo "CONFIG_BLK_DEV_DM_BUILTIN=y">>.config"
sudo bash -c "echo "CONFIG_BLK_DEV_SR_VENDOR=y">>.config"
sudo bash -c "echo "CONFIG_BLK_DEV_SR=m">>.config"
sudo sed -i '/^.*CONFIG_ISO9660_FS.*$/d' .config
sudo sed -i '/^.*CONFIG_UDF_FS.*$/d' .config
sudo bash -c "echo "CONFIG_ISO9660_FS=m">>.config"
sudo bash -c "echo "CONFIG_UDF_FS=m">>.config"
sudo bash -c "echo "CONFIG_CDROM=m">>.config"
sudo sed -i '/^.*CONFIG_BLK_DEV_DM.*$/d' .config
sudo bash -c "echo "CONFIG_BLK_DEV_DM=m">>.config"
sudo bash -c "echo "CONFIG_PARIDE=m">>.config"
sudo bash -c "echo "CONFIG_PARIDE_PCD=m">>.config"

sudo bash -c "echo "CONFIG_HYPERV_NET=m">>.config"
sudo bash -c "echo "CONFIG_HYPERV_KEYBOARD=m">>.config"
sudo bash -c "echo "CONFIG_HID_HYPERV_MOUSE=m">>.config"
sudo bash -c "echo "CONFIG_HYPERV=m">>.config"
sudo bash -c "echo "CONFIG_HYPERV_UTILS=m">>.config"
sudo bash -c "echo "CONFIG_HYPERV_BALLOON=m">>.config"
sudo bash -c "echo "CONFIG_PCI_HYPERV=m">>.config"
sudo bash -c "echo "CONFIG_HYPERV_STORAGE=m">>.config"
sudo bash -c "echo "CONFIG_FB_HYPERV=m">>.config"
sudo bash -c "echo "CONFIG_VMWARE_PVSCSI=m">>.config"
```

- Собрал ядро из исходников и модули (на виртуалке и хосте должно быть не менее 20 Gb свободного места)

```bash
echo "n" | sudo make -j $(nproc)
```

- Установил модули и ядро

```bash
sudo make modules_install
sudo make install
```

- Обновил конфиг GRUB и сделал загрузку по-умолчанию нового ядра

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
```

- Очистил каталог сборки

```bash
sudo make clean
```

- Выключил виртуалку

```bash
sudo shutdown -h now
```

- Подключил диск с vboxextentions

- Запустил виртуалку и зашел на нее

```bash
cd /home/zav/REPO/AleksZimin_linux/linux-kernel
MY_PROVIDER='virtualbox' vagrant up
vagrant ssh
```

- Проверил версию ядра

```bash
[vagrant@kernel-update ~]$ uname -r
4.19.109
```

## Задание с **: настроил VirtualBox Shared Folders

- Смонтировал диск с guest additions

```bash
lsblk
sudo mount /dev/sr0 /media
```

- Установил дополнения

```bash
cd /media
sudo ./VBoxLinuxAdditions.run
```

### Автоматизировал сборку с помощью packer

- Создал отдельную папку для скриптов packer

```bash
cd /home/zav/REPO/AleksZimin_linux/linux-kernel
mkdir packer-additional-task
cp -R packer/{http,scripts,*.json} packer-additional-task/
mv packer-additional-task/scripts/stage-1-kernel-update.sh packer-additional-task/scripts/stage-1-kernel-build.sh
```

- Изменил provisioner скрипты, а так же json для packer (объединил в один, увеличил таймауты, параметризировал объем диска, памяти, cpu, версию kernel и название артефакта) и запустил сборку образа (vbox guest additions версии 6.0.8 для ядра версии 5.4 и выше (?) не собрались. Дополнения успешно собрались на версии дополнений 6.0.18)

```bash
cd packer-additional-task

# packer build -only=qemu-centos-7.7 -var 'kernel_version=5.4.26' \

packer build -only=virtualbox-centos-7.7 -var 'kernel_version=5.4.26' \
  -var 'cpus=6' \
  -var 'memory=7000' \
  centos.json
```

- Импортировал созданные образы в Vagrant

```bash
cd ~/REPO/AleksZimin_linux/linux-kernel
MY_PROVIDER='virtualbox' vagrant box add --name centos-7-5.4-build packer-additional-task/packer_artifact/centos-build-7.7.1908-kernel-5.4.26-x86_64-Minimal.box
```

- Проверил список имеющихся образов

```bash
vagrant box list
  centos-7-5.4-build (virtualbox, 0)
```

- запустил виртуалку из нового образа

```bash
MY_PROVIDER='virtualbox' MY_BOX='centos-7-5.4-build' vagrant up
```

- Зашел на виртуальную машину,  проверил версию ядра и проверил работу второй и третьей стадии provisioning

```bash
MY_PROVIDER='virtualbox' vagrant ssh

[vagrant@kernel-update ~]$ uname -r
  5.4.26

[vagrant@kernel-update ~]$ sudo grep "Hi from" /boot/grub2/grub.cfg
  ###   Hi from second stage of kernel build
  ###   Hi from third stage of kernel build
```

- Проверил работу shared folders (файл test появился на хостовой системе)

```bash
cd /vagrant/
echo "Hi from guest with linux kernel $(uname -r)" > test
```

### Загрузил образ в Vagrant Cloud

- Залогинился в Vagrant Cloud в cli

```bash
vagrant cloud auth login
  Vagrant Cloud username or email: <user_email>
  Password (will be hidden):
  Token description (Defaults to "Vagrant login from DS-WS"):
  You are now logged in.
```

- Опубликовал полученный бокс

```bash
USERNAME=realzav
vagrant cloud publish --release $USERNAME/centos-7-5.4-build 1.0 virtualbox \
        packer-additional-task/packer_artifact/centos-build-7.7.1908-kernel-5.4.26-x86_64-Minimal.box
```

### [Вернуться в корень репо](/../../)
