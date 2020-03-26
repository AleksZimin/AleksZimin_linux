# Инструкции по установке

## HashiCorp utils

### Предварительно установим gpg ключ HashiCorp

- Ипортируем открытый ключ HashiCorp и проверяем ключ

```bash
gpg --keyserver pgp.mit.edu --recv 51852D87348FFC4C
gpg --fingerprint 91A6E7F85D05C65630BEF18951852D87348FFC4C
```

- Если вывод предыдущей команды в поле uid содержит подстроку "HashiCorp Security <security@hashicorp.com>", то добавляем ключ в доверенные ключи:

```bash
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key 91A6E7F85D05C65630BEF18951852D87348FFC4C trust
```

### Установка Vagrant

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

### Установка Packer

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

### Install provider vagrant-libvirt for Vagrant

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

## VirtualBox

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

## qemu-kvm

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
