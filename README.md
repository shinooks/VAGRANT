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

## Vagrantfile 주요 설정 정보

```ruby
Vagrant.configure("2") do |config|
  # Vagrant box 설정: 사용할 Vagrant box 이름과 버전 지정
  config.vm.box = "swhwang/ubuntu"  # 사용할 박스 지정
  config.vm.box_version = "1.0" # 사용할 버전 지정 (생략하면 Latest 설치)
  # VM 네트워크 설정: IP 주소를 할당하거나 네트워크 유형을 설정
  config.vm.network "private_network", ip: "192.168.33.10"
  
  # VM 자원 설정: 가상 머신의 CPU와 메모리 설정
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"  # 1GB 메모리 할당
    vb.cpus = 2         # 2개의 CPU 코어 할당
  end
  
  # 프로비저닝 설정: 쉘 스크립트 또는 다른 프로비저닝 도구를 사용해 설정 자동화
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y nginx
  SHELL
end