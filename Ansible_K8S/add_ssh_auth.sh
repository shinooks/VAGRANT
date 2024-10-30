#! /usr/bin/env bash

#ssh key 생성
sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@192.168.56.11
sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@192.168.56.12
sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@192.168.56.13