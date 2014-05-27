#!/bin/sh

SERVER=arldcn28
CLIENT=arldcn24

# run this on arldcn24
# you need to be part of the kvm group; try sudo usermod -a -G kvm `whoami`

LIBDIR=../common/vm
SSHOPTS="-p2222 -i ../common/id_rsa -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -oConnectionAttempts=60"

# prepare source disk images
make -C $LIBDIR

# create ephemeral overlay qcow image
# (we probably could have used -snapshot)
IMG=`mktemp tmpXXX.img`
qemu-img create -f qcow2 -b $LIBDIR/ubuntu-13.10-server-cloudimg-amd64-disk1.img $IMG

# TODO set up bridge

# start the VM & bind port 2222 on the host to port 22 in the VM
# TODO use fancy virtio
kvm -net nic -net user -hda $IMG -hdb $LIBDIR/seed.img -m 96G -smp 16 -nographic -redir :2222::22 >$IMG.log &

# remove the overlay (qemu will keep it open as needed)
sleep 2
rm $IMG

# TODO set up networking on the server
ssh $SERVER nuttcp -S &

# install nuttcp
ssh $SSHOPTS spyre@localhost sudo apt-get -qq install -y nuttcp

echo "transmit client->server"
ssh $SSHOPTS spyre@localhost nuttcp -l8000 -t -w4m -i1 -N4 10.71.0.23
echo "receive server->client (this matters because we only measure the client)"
ssh $SSHOPTS spyre@localhost nuttcp -l8000 -r -w4m -i1 -N4 10.71.0.23

# TODO copy out results

# shut down the VM
ssh $SSHOPTS spyre@localhost sudo shutdown -h now

wait
echo Experiment completed
