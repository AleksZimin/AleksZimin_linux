# Инструкции по работе с GCP

## Create VM with enabled nested virtualisation

- Задал необходимые переменные

```bash
VM_NAME=ubuntu18-nested
MY_PROJECT=linux-zav
DISK_SIZE=100GB

DISK_TYPE=pd-standard
#DISK_TYPE=pd-ssd
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
