#!/bin/bash
echo ">>>> Ansible 설치 중 <<<<"
sudo apt-get update
sudo apt-get install -y ansible
sudo ansible --version
sudo mkdir -p /etc/ansible
echo ">>>> Ansible 설치 완료 <<<<"