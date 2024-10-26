## Vagrant + Vmware 환경구성
### 1. Vagrant 설치
* 윈도우는 https://developer.hashicorp.com/vagrant/install에서 [실행파일로 설치]([https://developer.hashicorp.com/vagrant/install](https://releases.hashicorp.com/vagrant/2.4.1/vagrant_2.4.1_windows_amd64.msi))
* 우분투/데비안
    ```bash
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install vagrant
    ```
* 레드햇, 페도라, 아마존리눅스, MacOS는 페이지에서 찾아보기
### 2. Vmware 플러그인 설치
* 윈도우는 https://developer.hashicorp.com/vagrant/install/vmware에서 [실행파일로 설치](https://releases.hashicorp.com/vagrant-vmware-utility/1.0.23/vagrant-vmware-utility_1.0.23_windows_amd64.msi)
### 3. Vmware 플러그인 등록
* Virtual Machine 외 다른 프로바이더를 이용할 경우 각 프로바이더에 맞는 플러그인 등록 필요
* ```bash
  vagrant plugin install vagrant-vmware-desktop
  ```
### 4. `Vagrant init`으로 Vagrantfile 초기화
* 프로젝트 폴더를 생성하고 터미널을 이용해 `Vagrant init` 명령어 입력
* 폴더 내에 Vagrantfile이 생성됩니다. 이미 있다면 명령어 실행 X
* Vagrantfile을 직접 생성해도 됩니다.
### 5. Vagrantfile 전역 구성
```ruby
Vagrant.configure("2") do |config|
  # 사용할 박스를 설정 (예: Ubuntu 22.04)
  config.vm.box = "generic/ubuntu2204" # 원하는 박스 이름으로 변경 가능

  # VMware Desktop을 프로바이더로 설정
  config.vm.provider "vmware_desktop" do |v|
    # VMware
  end
end
```
### 6. Vagrantfile 지역 구성
* Vagrantfile에서 독립적인 설정을 하려면 `config.vm.define`으로 프로비저닝 환경을 정의합니다.
```ruby
Vagrant.configure("2") do |config|
  # 첫 번째 VM 설정 (예: 웹 서버)
  config.vm.define "web" do |web|
    web.vm.box = "generic/ubuntu2204"
    web.vm.hostname = "web-server"
    web.vm.provider "vmware_desktop"
  end

  # 두 번째 VM 설정 (예: 데이터베이스 서버)
  config.vm.define "db" do |db|
    db.vm.box = "generic/ubuntu2204"
    db.vm.hostname = "db-server"
    db.vm.provider "vmware_desktop"
  end
end
```
* VM을 프로비저닝하는 `vagrant up`을 입력하면 모든 define이 프로비저닝 됩니다.
### 7. Vagrantfile 실행 및 업데이트
* 이미 다른 VM이 동작 중인 상태에서 새로운 VM을 프로비저닝 하려면 'vagrant up db` 와 같이 이름으로 호출합니다.
* 이미 동작 중인 특정 VM을 업데이트하기 위해서는 'vagrant provision db'와 같이 이름으로 호출합니다.

### 8. Vagrant 부분 수정 & 추가
* 기본적으로 `vagrant provision`은 이미 정의된 프로비저닝만 다시 수행합니다.
* 새로운 프로비저닝을 추가했다면 `vagrant reload --provision`(VM 재시작 -> VM 꺼졌다 켜짐)
* 또는 `vagrant provision <VM 이름(생략가능)> --provision-with <프로비저닝 이름>` 과 같이 지정해서 실행해야 합니다. (VM 중단 없이 명령 실행)
* 아래와 같이 프로비저닝 명령 단위로 이름을 부여해야 합니다.
* * `ansible.vm.provision "shell", path: "install_ansible.sh" name: "install_ansible*`
## Vagrant 주요 명령어

| 명령어                | 설명                                                                  |
|-----------------------|-----------------------------------------------------------------------|
| `vagrant init`        | Vagrant 환경을 초기화하고 Vagrantfile을 생성합니다.                     |
| `vagrant up`          | 정의된 Vagrant 환경을 시작하고 가상 머신을 실행합니다.                  |
| `vagrant halt`        | 가상 머신을 중지합니다.                                                |
| `vagrant reload`      | 가상 머신을 재시작하며 Vagrantfile의 변경 사항을 적용합니다.           |
| `vagrant ssh`         | 가상 머신에 SSH로 접속합니다.                                         |
| `vagrant destroy`     | 가상 머신을 삭제합니다.                                                |
| `vagrant status`      | 현재 Vagrant 환경의 상태를 확인합니다.                                |
| `vagrant provision`   | 프로비저닝 스크립트를 다시 실행하여 설정을 적용합니다.                |
| `vagrant box list`    | 현재 사용 가능한 Vagrant Box 목록을 확인합니다.                        |
| `vagrant box add`     | 새로운 Vagrant Box를 추가합니다.                                       |
| `vagrant box remove`  | 사용하지 않는 Vagrant Box를 제거합니다.                                |
| `vagrant package`     | 현재 Vagrant 환경을 `.box` 파일로 패키징합니다.                        |

---

## Vagrantfile 주요 설정 정보 예시

```ruby
# 필수 Vagrantfile 시작 - VMware Desktop Provider를 사용하는 다중 머신 환경 설정
Vagrant.configure("2") do |config|  # config는 모든 머신에 적용되는 전역 설정 시 사용

  ################
  # VM 전역 설정  #
  ################
  
  # 기본 박스 설정 - 모든 머신에서 공통적으로 사용할 박스
  config.vm.box = "swhwang/ubuntu"  # 사용할 박스 지정
  config.vm.box_version = "1.0"  # 사용할 박스 버전 지정 (생략 시 최신 버전 사용)
  
  # VM 네트워크 전역 설정: DHCP를 이용한 IP 할당
  # 개별 머신에서 IP 설정을 오버라이드할 수 있습니다.
  config.vm.network "private_network", type: "dhcp"
  
  # VMware Provider 전역 자원 설정 - 모든 머신에게 적용될 기본 리소스 값 지정
  # 각 머신에서 개별적으로 오버라이드할 수 있습니다.
  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui = false  # GUI를 비활성화하여 헤드리스 모드로 실행 (필요에 따라 true로 설정)
    vmware.memory = "1024"  # 1GB 메모리 할당
    vmware.cpus = 1         # 1개의 CPU 코어 할당
    vmware.linked_clone = true  # 링크드 클론 활성화로 더 적은 디스크 공간 사용
  end

  # 전역 프로비저닝 설정: 모든 머신에서 공통적으로 실행될 명령을 정의
  # 예: 업데이트 명령
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
  SHELL

  ################
  # VM 개별 설정  #
  ################
  
  # 웹 서버 머신 설정
  config.vm.define "web" do |web|
    web.vm.hostname = "web-server"  # 웹 서버 머신의 호스트 이름 설정
    web.vm.network "private_network", ip: "192.168.33.10"  # IP 주소 오버라이드
    
    # VMware Provider 개별 설정 - 웹 서버에 적용될 리소스 설정
    web.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = false  # 웹 서버는 GUI 없이 실행
      vmware.memory = "2048"  # 2GB 메모리 할당
      vmware.cpus = 2         # 2개의 CPU 코어 사용
      vmware.linked_clone = false  # 링크드 클론 비활성화
    end

    # 웹 서버 전용 쉘 프로비저닝 예시 - Nginx 설치
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt-get install -y nginx
    SHELL
  end
  
  # 데이터베이스 서버 머신 설정
  config.vm.define "db" do |db|
    db.vm.hostname = "db-server"  # 데이터베이스 서버 머신의 호스트 이름 설정
    db.vm.network "private_network", ip: "192.168.33.11"  # IP 주소 오버라이드
    
    # VMware Provider 개별 설정 - 데이터베이스 서버에 적용될 리소스 설정
    db.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = false  # 데이터베이스 서버는 GUI 없이 실행
      vmware.memory = "4096"  # 4GB 메모리 할당
      vmware.cpus = 2         # 2개의 CPU 코어 사용
    end

    # DB 서버 전용 쉘 프로비저닝 예시 - MySQL 설치
    db.vm.provision "shell", inline: <<-SHELL
      sudo apt-get install -y mysql-server
    SHELL
  end

end
