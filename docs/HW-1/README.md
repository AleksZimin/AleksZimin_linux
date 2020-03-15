### [Вернуться в корень репо](/../../)

## Предварительные действия

### Подготовил виртуалку в GCP с включенной вложенной виртуализацией

- Задал необходимые переменные

```bash
VM_NAME=ubuntu18-nested
MY_PROJECT=linux-zav
DISK_SIZE=100GB

DISK_TYPE=pd-standard
MY_ZONE=europe-north1-b
VM_OS=ubuntu-os-cloud
VM_OS_VER=ubuntu-1804-lts
```

- Перешел в свой в проект

```bash
gcloud config set project $MY_PROJECT
```

- Создал загрузочный диск с лицензией для вложенной виртуализации

```bash
gcloud compute disks create disk1 \
  --image-project $VM_OS \
  --image-family $VM_OS_VER \
  --zone $MY_ZONE \
  --size=$DISK_SIZE \
  --type=$DISK_TYPE

gcloud compute images create nested-vm-image \
  --source-disk disk1 --source-disk-zone $MY_ZONE \
  --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

gcloud compute disks delete disk1 --zone $MY_ZONE
```

- Создал ВМ с загрузочным диском, созданным выше

```bash
gcloud compute instances create $VM_NAME\
  --min-cpu-platform "Intel Skylake" \
  --machine-type=custom-6-10240 \
  --image nested-vm-image \
  --boot-disk-type=$DISK_TYPE \
  --boot-disk-size=$DISK_SIZE \
  --zone=$MY_ZONE \
  --restart-on-failure
```

- Зашел на созданную виртуалку и проверил вложенную виртуализацию (команда должна вывести кол-во ядер, если виртуализация включена):

```bash
gcloud compute ssh $VM_NAME
egrep -c '(vmx|svm)' /proc/cpuinfo
```

### Установил gpg ключ HashiCorp на виртуалку в GCP

- Ипортируем открытый ключ HashiCorp и проверяем ключ

```bash
gpg --keyserver pgp.mit.edu --recv 51852D87348FFC4C
gpg --fingerprint 91A6E7F85D05C65630BEF18951852D87348FFC4C
```

- Если вывод предыдущей команды в поле uid содержит подстроку "HashiCorp Security <security@hashicorp.com>", то добавляем ключ в доверенные ключи:

```bash
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key 91A6E7F85D05C65630BEF18951852D87348FFC4C trust
```

### Установил Vagrant на виртуалку в GCP

- Задаем версию Vagrant, версию ОС, скачиваем файл с хешами пакетов и бинарников Vagrant, ЭЦП для него и пакет для выбранной ОС

```bash
VAGRANT_VER=2.2.7
OS_VER=x86_64.deb
mkdir -p ~/distib/vagrant/$VAGRANT_VER && cd ~/distib/vagrant/$VAGRANT_VER
curl -s --remote-name-all https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_{SHA256SUMS,SHA256SUMS.sig,${OS_VER}}
```

- Проверяем подлинность файла с хешами (в выводе команды должна быть подстрока "Good signature from "HashiCorp Security <security@hashicorp.com>"")

```bash
gpg --verify vagrant_${VAGRANT_VER}_{SHA256SUMS.sig,SHA256SUMS}
```

- Проверяем хеш пакета:

```bash
grep vagrant_${VAGRANT_VER}_${OS_VER} vagrant_${VAGRANT_VER}_SHA256SUMS | shasum -a 256 -c -
```

- Если хеши совпадают, то устанавливаем Vagrant (команда ниже для Debian-like систем)

```bash
sudo dpkg -i vagrant_${VAGRANT_VER}_${OS_VER}
```

### Установил Packer на виртуалку в GCP

- Задаем версию Packer, версию ОС, скачиваем файл с хешами пакетов и бинарников Packer, ЭЦП для него и архив с бинарником для Linux

```bash
PACKER_VER=1.5.4
OS_VER=linux_amd64.zip
mkdir -p ~/distib/packer/$PACKER_VER && cd ~/distib/packer/$PACKER_VER
curl -s --remote-name-all https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_{SHA256SUMS,SHA256SUMS.sig,${OS_VER}}
```

- Проверяем подлинность файла с хешами (в выводе команды должна быть подстрока "Good signature from "HashiCorp Security <security@hashicorp.com>"")

```bash
gpg --verify packer_${PACKER_VER}_{SHA256SUMS.sig,SHA256SUMS}
```

- Проверяем хеш пакета:

```bash
grep packer_${PACKER_VER}_${OS_VER} packer_${PACKER_VER}_SHA256SUMS | shasum -a 256 -c -
```

- Если хеши совпадают, то устанавливаем Packer

```bash
zcat packer_${PACKER_VER}_${OS_VER} | sudo tee /usr/local/bin/packer >/dev/null && \
  sudo chmod +x /usr/local/bin/packer
```

### Установил VirtualBox на виртуалку в GCP

- Добавил репозиторий Vbox

```bash
sudo add-apt-repository "deb https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
```

- Добавил открытые ключи для apt-secure

```bash
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
```

- Проверяем ключи

```bash
apt-key finger B9F8D658297AF3EFC18D5CDFA2F683C52980AECF
apt-key finger 7B0FAB3A13B907435925D9C954422A4B98AB5139
```

- Если вывод предыдущих команд в поле uid содержит подстроку "Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>", то устанавливаем Vbox

```bash
sudo apt-get update
sudo apt-get install virtualbox-6.1
```

- Установил extention pack

```bash
mkdir -p ~/distib/virtualbox && cd ~/distib/virtualbox
curl -O https://download.virtualbox.org/virtualbox/6.1.4/Oracle_VM_VirtualBox_Extension_Pack-6.1.4.vbox-extpack
sudo vboxmanage extpack install ./Oracle_VM_VirtualBox_Extension_Pack-6.1.4.vbox-extpack
```

### Установил qemu-kvm и провайдер vagrant-libvirt для Vagrant на виртуалку в GCP

- Проверил хост на возможность работы kvm

```bash
sudo apt-get update && sudo apt-get install cpu-checker
sudo kvm-ok
```

- Установил необходимые пакеты для работы с kvm

```bash
sudo apt-get update &&\
 sudo apt-get install uml-utilities qemu-kvm bridge-utils virtinst libvirt-bin -y
```

- Проверил службу libvirt (она должна быть в статусе enabled)

```bash
sudo systemctl status libvirt-bin
```

- Проверил наличие моста для виртуалок

```bash
sudo ifconfig -a | grep virbr -A 6
```

- Добавил своего пользователя в группы libvirt и kvm, чтобы можно было управлять виртуалками без sudo

```bash
sudo usermod -a -G libvirt,kvm $USER
```

- Обновил текущий shell, чтобы изменения в группах применились

```bash
exec newgrp kvm
exec newgrp libvirt
```

- Проверил подключение к гипервизору (выйти из virsh можно с помощью команды quit)

```bash
virsh --connect qemu:///system
```

- Добавил репо с universe пакетами (Community maintained software, i.e. not officially supported software.)

```bash
sudo bash -c 'echo "deb-src http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs) universe" >> /etc/apt/sources.list.d/deb-src.list'
sudo apt update
```

- Установил нобходимые пакеты для работы провайдера vagrant-libvirt (используется команда apt-get build-dep для установки всех необходимых для сборки зависимостей)

```bash
sudo apt-get build-dep vagrant ruby-libvirt
sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
```

- Установил провайдер vagrant-libvirt

```bash
vagrant plugin install vagrant-libvirt
```

- Задал переменную окружения, в которой указал провайдер по-умолчанию для Vagrant

```bash
export VAGRANT_DEFAULT_PROVIDER=libvirt
```

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

- Создал аккаунт в https://app.vagrantup.com/

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



















### [Вернуться в корень репо](/../../)
