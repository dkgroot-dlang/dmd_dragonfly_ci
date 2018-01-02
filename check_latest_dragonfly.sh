#!/usr/bin/env bash
if [ -d $SEMAPHORE_CACHE_DIR ]; then
      pushd $SEMAPHORE_CACHE_DIR
      curl -s http://ftp.tu-clausthal.de/pub/DragonFly/snapshots/df_timestamp.txt -o df_timestamp.txt
      [ ! -f prev_timestamp.txt ] || [ ! -z "`diff df_timestamp.txt prev_timestamp.txt`" ] && {
            [ -f image.qcow ] && rm image.qcow
            sudo apt install -y python3-cairo python3-gi python3-gi-cairo python3-sqlalchemy python3-psutil python3-pip
            sudo pip3 install pexpect
            curl -s http://ftp.tu-clausthal.de/pub/DragonFly/snapshots/x86_64/DragonFly-x86_64-LATEST-ISO.iso.bz2 -o - |pbzip2 -d -c - >DragonFly-x86_64-LATEST-ISO.iso
            qemu-img create -f qcow2 image.img 10G
            ls -sl --block-size 1 image.img
            sudo ../scripts/install_dfly.py;
            ls -sl --block-size 1 image.img
            cp df_timestamp.txt prev_timestamp.txt;
            echo "DragonFly has been installed"
            #pbzip2 -z image.img -c > image.img.bz2
            #mv image.img ..
            rm DragonFly-x86_64-LATEST-ISO.iso
      }
      popd
fi
