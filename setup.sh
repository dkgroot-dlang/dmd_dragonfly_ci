#!/usr/bin/env bash
echo "Starting DragonFly..."
sudo qemu-system-x86_64 \
    -smp 4,sockets=1,cores=4,threads=2,maxcpus=4 \
    -enable-kvm \
    -device virtio-scsi-pci,id=scsi1 -device scsi-hd,drive=drive0,bus=scsi1.0 -drive file=$SEMAPHORE_CACHE_DIR/image.img,if=none,format=qcow2,id=drive0 \
    -snapshot \
    -m 3072 -device e1000,netdev=net1 \
    -netdev user,id=net1,hostfwd=tcp::10022-:22 \
    -boot order=c,menu=off,splash-time=0 \
    -no-reboot -daemonize \
    -monitor tcp:127.0.0.1:4555,server,nowait -chardev socket,host=127.0.0.1,port=4556,id=gnc0,server,nowait  -device isa-serial,chardev=gnc0
echo "Waiting for DragonFly to finish booting..."
sleep 50
if [ ! `pidof qemu-system-x86_64` ]; then echo "qemu failed to start"; exit 1; fi
ssh-keyscan -p10022 -H localhost >> ~/.ssh/known_hosts 2>/dev/null
ssh root@localhost -p 10022  -o ConnectTimeout=5 'curl -s https://raw.githubusercontent.com/dkgroot/dmd_dragonflybsd/master/scripts/execute_return_exitcode.sh -o execute_return_exitcode.sh && chmod a+x execute_return_exitcode.sh'
./runssh 'curl -s https://raw.githubusercontent.com/dkgroot/dmd_dragonfly_ci/master/scripts/bootstrap.mk -o bootstrap.mk'
./runssh 'curl -s https://raw.githubusercontent.com/dkgroot/dmd_dragonfly_ci/master/scripts/master.mk -o master.mk'
echo "DragonFly Started..."
