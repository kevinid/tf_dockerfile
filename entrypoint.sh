#! /bin/bash

# start sshd server
/usr/sbin/sshd

# start jupyter & tensorboard
nohup jupyter notebook --port 17288 --allow-root "$@" &
nohup tensorboard --logdir=/tmp  --port=17287 &


/sbin/iptables -I INPUT -p tcp --dport 17266:17288 -j ACCEPT 