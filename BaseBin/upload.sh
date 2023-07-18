#!/bin/sh

./pack.sh || exit

DEVICE=root@iphone13.local
PORT=22
ssh $DEVICE -p $PORT "rm -rf /var/mobile/Documents/basebin.tar"
scp -P$PORT ../Dopamine/Dopamine/bootstrap/basebin.tar $DEVICE:/var/mobile/Documents/basebin.tar
ssh $DEVICE -p $PORT "/var/jb/basebin/jbctl update basebin /var/mobile/Documents/basebin.tar"
