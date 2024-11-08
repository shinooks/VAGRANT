
# Vagrant을 이용한 가상화 환경 내 Kubernetes 클러스터 프로비저닝

## 프로젝트 개요
이 프로젝트는 Vagrant을 이용해 다중 VM에 Kubernetes 클러스터를 자동으로 프로비저닝하는 환경을 구성하는 방법을 다룹니다.<br>
Vagrant의 `SSH Provider`와 `kubeadm`을 이용, 쉘 스크립트로 Kubernetes 마스터와 워커 노드에 대한 설정을 자동화하고, 클러스터의 초기 구성을 진행합니다.
---
## 1. Vagrant로 멀티 VM 프로비저닝 구성
* `config.vm.define`을 통해 여러 VM에 각기 다른 설정을 부여할 수 있습니다.
* IP, 서비스 포트, 동기화 폴더와 같은 각종 설정을 VM마다 정의하여 Kubernetes 클러스터 환경을 구성합니다.

### 예시: Vagrantfile 설정
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.12"

  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui = true #gui를 
    vmware.memory = "2048"
    vmware.cpus = 2
  end

  # Kubernetes 마스터 노드 설정
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "public_network", ip: "192.168.56.11"
    master.vm.network "forwarded_port", guest: 6443, host: 6443, id: "k8s_api_server"
    master.vm.network "forwarded_port", guest: 10250, host: 10250, id: "kubelet"
  end

  # Kubernetes 워커 노드 설정
  (1..3).each do |i|
    config.vm.define "k8s-worker#{i}" do |worker|
      worker.vm.hostname = "k8s-worker#{i}"
      worker.vm.network "public_network", ip: "192.168.56.1#{i+1}"
    end
  end
end
```

## 2. Ansible Local Provisioner를 통한 초기 구성

### Ansible Local Provisioner 설정
Ansible Local Provisioner를 통해 Ansible 서버가 게스트 내에서 직접 Ansible 플레이북을 실행하고 Kubernetes 마스터 및 워커 노드를 설정하도록 합니다.

```ruby
config.vm.define "ansible-server" do |ansible|
  ansible.vm.hostname = "ansible-server"
  ansible.vm.network "public_network", ip: "192.168.56.10"
  
  # Ansible Local Provisioner 설정
  ansible.vm.provision "ansible_local" do |ansible_local|
    ansible_local.playbook = "ansible_env_ready.yml"       # 실행할 Ansible 플레이북 파일
    ansible_local.install = true                           # Ansible 자동 설치
    ansible_local.install_mode = :pip                      # pip을 통해 Ansible 설치
    ansible_local.version = "latest"                       # Ansible 최신 버전 설치
    ansible_local.inventory_path = "inventory.ini"         # 인벤토리 파일 설정
  end
end
```

### `pre_install.sh` 스크립트
Ansible 설치 전 초기 환경 구성을 위한 패키지 업데이트 스크립트입니다.

```bash
#!/bin/bash
echo ">>>> 패키지 목록 업데이트 <<<<"
sudo apt-get update && sudo apt-get upgrade -y
echo ">>>> pre-install 완료 <<<<"
```

## 3. Ansible 인벤토리 구성

### 인벤토리 파일: `inventory.ini`
Ansible 서버에서 Kubernetes 마스터와 워커 노드의 연결을 관리하는 인벤토리 파일입니다.

```ini
[k8s-master]
192.168.56.11 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/k8s-master/vmware_desktop/private_key

[k8s-workers]
192.168.56.12 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/k8s-worker1/vmware_desktop/private_key
192.168.56.13 ansible_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/k8s-worker2/vmware_desktop/private_key

[all:children]
k8s-master
k8s-workers
```

## 4. Ansible 플레이북: `ansible_env_ready.yml`

### 설정 파일 내용
Ansible 서버의 환경을 초기화하고, Kubernetes 마스터와 워커 노드를 위한 인벤토리 설정을 추가합니다.

```yaml
---
- name: Setup for the Ansible Environment
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Configure Bashrc with Ansible Aliases
      lineinfile:
        path: /home/vagrant/.bashrc
        line: "{{ item }}"
      with_items:
        - "alias ans='ansible'"
        - "alias anp='ansible-playbook'"
```

## 5. 결과 확인하기
1. `vagrant up`을 실행하여 모든 VM을 시작하고 프로비저닝을 수행합니다.
2. Ansible 서버에 접속하여 설정이 적용되었는지 확인합니다.

   ```bash
   vagrant ssh ansible-server
   ```

3. 다음 사항을 확인합니다:
   - playbook의 실행 결과를 확인하기
   ```
   TASK [Configure Bashrc] ********************************************************
   changed: [127.0.0.1] => (item=alias ans='ansible')
   changed: [127.0.0.1] => (item=alias anp='ansible-playbook')
   PLAY RECAP *********************************************************************
   127.0.0.1                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
   - ansible-sever로 접속해 확인하기
     - `vagrant ssh ansible-server` 로 엔시블 서버에 접속
     - `ans` 및 `anp` 명령어 별칭이 `.bashrc`에 추가되었는지 확인
     - `/etc/ansible/hosts` 파일에 Kubernetes 마스터 및 워커 노드가 설정되었는지 확인
   
   ```text
   # /etc/ansible/hosts 내용 예시
   # BEGIN ANSIBLE MANAGED BLOCK
   [k8s-master]
   192.168.56.11
          
   [k8s-workers]
   192.168.56.12
   192.168.56.13
   # END ANSIBLE MANAGED BLOCK
   ```

> **Note**: Ansible의 Task는 멱등성을 갖습니다. 즉, 동일한 Task를 반복 실행해도 결과는 동일하며, 파일에 중복으로 추가되지 않습니다. Ansible을 통해 일관성 있는 관리가 가능합니다.
