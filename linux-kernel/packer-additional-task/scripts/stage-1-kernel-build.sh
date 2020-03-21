#!/bin/bash

while [ -n "$1" ]; do
  case "$1" in
    -kernel)
      shift
      KERNEL_VER="$1"
    ;;
    -params)
      shift
      BUILD_PARAMS_PATH="$1"
    ;;
    *)
      echo "$1 is a bad option! Use "-kernel" key to set desired kernel version or "-params" to set path to file with additional build params"
    ;;
  esac
  shift
done

if [ -z "$KERNEL_VER" ]; then
  echo "Kernel version is not set! Use default value. KERNEL_VER=4.19.109. Use "-kernel" key or env variable KERNEL_VER to set another kernel version "
  KERNEL_VER=4.19.109
else
  reg_exp="^([0-9]\.)+([0-9]{1,2}\.)+([0-9]{1,3})$"
  if [[ $KERNEL_VER =~ $reg_exp ]]; then 
    echo "Kernel version set to $KERNEL_VER"
  else
    echo "Bad parameter for kernel version! KERNEL_VER=$KERNEL_VER is not match regexp '^([0-9]\.)+([0-9]{1,2}\.)+([0-9]{1,3})$'! Exit from script"
    exit 1
  fi
fi



MAJOR_VER=$(echo $KERNEL_VER | cut -d '.' -f 1)
echo "KERNEL_VER=$KERNEL_VER      MAJOR_VER=$MAJOR_VER"


# Install requied packages
sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 perl

# Install pgp keys
gpg --keyserver pgp.mit.edu --recv {ABAF11C65A2970B130ABE3C479BE3E4300411886,\
647F28654894E3BD457199BE38DBBDC86092693E,\
E27E5D8A3403A2EF66873BBCDEA66FF797772CDC,\
AC2B29BD34A6AFDDB3F68F35E7BFC8EC95861109}

echo -e "5\ny\n" | gpg --command-fd 0 --edit-key {ABAF11C65A2970B130ABE3C479BE3E4300411886,\
647F28654894E3BD457199BE38DBBDC86092693E,\
E27E5D8A3403A2EF66873BBCDEA66FF797772CDC,\
AC2B29BD34A6AFDDB3F68F35E7BFC8EC95861109} trust

# Download resources
cd /usr/src/
sudo curl --remote-name-all https://cdn.kernel.org/pub/linux/kernel/v${MAJOR_VER}.x/linux-${KERNEL_VER}.tar.{sign,xz}

# Extract and verify archive
xz -cd linux-${KERNEL_VER}.tar.xz | tee >(sudo tar -x) | gpg2 --verify linux-${KERNEL_VER}.tar.sign -

# Configure build
cd linux-${KERNEL_VER}
sudo cp -v /boot/config-$(uname -r) .config
sudo make olddefconfig
echo "N" | sudo make localmodconfig

if [ -n "$BUILD_PARAMS_PATH" ]; then
  echo "Path to file with additional build params=${BUILD_PARAMS_PATH}. It contains params:"
  if [ -f "$BUILD_PARAMS_PATH" ]; then
    cat "$BUILD_PARAMS_PATH" | sudo tee -a .config
    echo && sudo make olddefconfig
  else
    echo "Error! ${BUILD_PARAMS_PATH} is not file! Kernel will build with default params"
  fi
fi

# Build kernel and modules
sudo make -j $(nproc)

# Install Linux kernel modules
sudo make modules_install

# Install new kernel
sudo make install

# Cleanup
sudo make clean


# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."

# Reboot VM
shutdown -r now
