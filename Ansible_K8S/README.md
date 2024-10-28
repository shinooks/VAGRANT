# Vagrant과 Ansible을 이용한 K8s 프로비저닝

## 1. Vagrant에서 멀티 프로비저닝 구성
* configure.vm.define으로 여러 vm들에게 각기 다른 설정을 부여할 수 있습니다.
* 예를 들어, 
  * IP의 경우 전역 설정과 DHCP를 사용할 경우 프로비저닝 단계에서 어떤 IP가 부여될지 모릅니다.
  * VM마다 개별적으로 설정되어야 하는 IP는 define 내에 정의할 수 있습니다.
  * VM마다 서비스 포트가 다른 경우도 포트포워딩을 define 내에서 정의합니다.
```hcl
# Ansible 서버
config.vm.define "ansible-server" do |ansible|
  ansible.vm.hostname = "ansible-server"
  ansible.vm.network "public_network", ip: "192.168.56.10"
  ansible.vm.provision "shell", path: "install_ansible.sh", name: "install_ansible"
end

# Kubernetes 마스터 노드
config.vm.define "k8s-master" do |master|
  master.vm.hostname = "k8s-master"
  master.vm.network "public_network", ip: "192.168.56.11"
  # Kubernetes API Server (6443): 외부에서 Kubernetes API에 접근할 때 필요한 포트
  master.vm.network "forwarded_port", guest: 6443, host: 6443, id: "k8s_api_server"

  # Kubelet (10250): Kubernetes 노드와 상호작용할 때 사용
  master.vm.network "forwarded_port", guest: 10250, host: 10250, id: "kubelet"
end

# Kubernetes 워커 노드
(1..2).each do |i|
  config.vm.define "k8s-worker#{i}" do |worker|
    worker.vm.hostname = "k8s-worker#{i}"
    worker.vm.network "public_network", ip: "192.168.56.1#{i+1}"
end
```

## 2. Ansible 초기 구성
### Ansible의 게스트 관리 방법
* Ansible은 서버측에서 SSH 접속을 이용해 클라이언트 측에서 실행,혹은 배포하는 방식
* 클라이언트를 찾기 위해 `/etc/ansible/hosts` 하위에서 클라이언트 정보가 담긴 인벤토리를 참조한다.

### Ansible 인벤토리 구성
1. 인벤토리란?
* 클라이언트와 Ansible 내에서 식별 가능한 노드 그룹의 형태로 정보를 담고 있는 파일
* 인벤토리 내용은 다음과 같다.
```ini
[k8s-master]
192.168.56.11

[k8s-workers]
192.168.56.12
192.168.56.13
```
2. 플레이북 추가하기
* 인벤토리를 추가하는 여러 방법 중 Vagrant로 Ansible 플레이북을 넘겨 실행하는 방식 사용
* Ansible 서버 define에 다음 구문을 추가한다.
```hcl
config.vm.define "ansible-server" do |ansible|
...
    # 동일 경로의 Ansible 플레이북 파일을 서버 내부로 이동해 실행하는 구문
    ansible.vm.provision "file", source: "ansible_env_ready.yml", destination: "ansible_env_ready.yml"
    ansible.vm.provision "shell", inline: "ansible-playbook ansible_env_ready.yml"
end
```
3. 플레이북 정의하기
```yaml
---
- name: Setup for the Ansible's Environment
  hosts: localhost
  gather_facts: no
  # tasks는 hosts(노드 그룹 등)를 대상으로 name으로 구분된 작업을 순차적으로 수행
  tasks:
    - name: Configure Bashrc
      # lineinfile 모듈은 line에 정의된 내용을 기존 파일에 한 줄씩 추가하는 모듈
      lineinfile:
        path: /home/vagrant/.bashrc
        line: "{{ item }}"
      # item과 with_items는 반복적으로 실행되는 명령을 리스트 형태로 선언
      with_items:
        - "alias ans='ansible'"
        - "alias anp='ansible-playbook'" 
    
    - name: Add "/etc/ansible/hosts"
      # blockinfile 모듈은 블록 내에 정의된 내용을 파일 형태로 저장하는 모듈
      # hosts 파일에 한글 주석이 들어가면 간혹 오류가 발생한다.
      blockinfile:
        path: /etc/ansible/hosts
        block: |
          [k8s-master]
          192.168.56.11
          
          [k8s-workers]
          192.168.56.12
          192.168.56.13
```
4. 결과 확인하기
* 결과를 확인하기 위해서는 추가된 구문을 프로비저닝 해야 한다.
* `vagrant reload --provision` 혹은 `vagrant provision 옵션`으로 적용한다.
* 프로비저닝이 적용 되었으면 `vagrant ssh ansible-server`로 서버에 들어가 변경 사항을 확인.
  * 쉘에서 `ans`, `anp` 명령어를 입력하고 등록이 되었는지 확인
  * `/etc/ansible/hosts`에 다음 내용이 추가되었는지 확인하기
  ```text
  # BEGIN ANSIBLE MANAGED BLOCK
  [k8s-master]
  192.168.56.11
          
  [k8s-workers]
  192.168.56.12
  192.168.56.13
  # END ANSIBLE MANAGED BLOCK
  ```

> ### Ansible의 Task는 멱등성을 갖는다.
> 쉽게 말하면 똑같은 파일을 2번 실행한다 해서 hosts 파일 내에 내용이 2번 들어가지는 않는다는 뜻이다.<br>
> 인벤토리에 내용이 추가되었다면 추가된 부분만큼만 실행되서 언제나 일관적인 내용으로 관리할 수 있는 것이 Ansible의 장점