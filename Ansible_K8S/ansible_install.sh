#!/bin/bash
echo ">>>> Ansible 설치 중 <<<<"
sudo apt-get install -y ansible
sudo ansible --version
sudo mkdir -p /etc/ansible
sudo touch /etc/ansible/hosts
echo ">>>> Ansible 설치 완료 <<<<"