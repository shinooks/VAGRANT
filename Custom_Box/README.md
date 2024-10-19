# Vagrant 커스텀 이미지(Box) 생성하기

## 1. VMware
> **VMware 설치하기**
>
>이전까지는 오픈 소스인 Oracle Virtual Box를 많이 이용했기 때문에 대부분의 프로비저닝 이미지(Box)가 Virtual Box로 제공되었다.<br>
>
>하지만 2024.04.15를 기준으로 개인 용도로는 **VMware Workstation Pro를** 무료로 사용할 수 있도록 라이센스가 변경되었기 때문에 프로비저닝 도구로 Virtual Box 대신 VMware를 사용했다.<br>
>
>Workstation Pro는 Virtual Box보다 고성능과 안정적인 가상화 환경을 제공한다.(~~라고 하더라.~~<br>
>경험 상으로도 온프레미스 환경에서 VMware 기반의 가상화 환경이 더 많았고 운영 레벨에서 Virtual Box를 사용하는 경우는 있었나 싶다.)
>
> 단, 무료로 풀리긴 했지만 브로드컴에서 설치하는 과정은 매우 번거롭다.<br>
> 아래 경로는 다 건너뛰고 vmware의 cds repository로부터 직접 다운로드를 받는 경로.<br>
> 당연하게도 언제든지 막힐 수 있다.
>
> [VMware Workstation pro를 호스트(윈도우)에 설치](https://softwareupdate.vmware.com/cds/vmw-desktop/ws/17.6.0/24238078/windows/core/)

### 1) 베이스 이미지 설치

리눅스 OS: Ubuntu 22.04 - Minimized Server<br>

> **Minimized Server**는 기본적인 운영체제 기능만 제공하며, 필요할 때마다 추가 패키지를 설치하는 방식. 단순히 vagrant의 빠른 배포를 위해 채택하였다.<br>
> (박스를 만들고 보니 Minimized도 2.1GB.. 클라우드를 이용하기에는 여전히 무겁다.)


### 2) Vagrant 사용자 구성
기본적으로 vagrant에서 제공하는 OS 이미지들은 vagrant라는 계정을 ssh로 접근해 프로비저닝하는 방식이다.

- 필요한 설정: ID:vagrant/PW:vagrant 계정 구성, ssh 접속 가능, vagrant 계정의 sudoers 그룹 소속 설정

    ```bash
    # vagrant 사용자 추가
    sudo adduser vagrant
    
    # sudo 권한 추가 및 비밀번호 요구 제거
    sudo usermod -aG sudo vagrant
    echo "vagrant ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/vagrant
    
    # SSH 키 설정
    mkdir /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    curl -L https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
    ```


### 선택) 미러 리포지터리 변경

기본 리포지터리를 사용해도 되지만, 사용자 체감 상 카카오의 리포지터리가 빠르다는 평이 많다.<br>
필요하다면 미러 리포지터리 경로를 바꾸자

Mirror address: http://mirror.kakao.com/ubuntu/

### 선택) 패키지 인스톨 및 환경 설정

프로비저닝 단계에서 리포지터리의 update와 upgrade는 반복적으로 요구된다.<br> 
이 작업을 현 단계에서 미리 수행한다면 프로비저닝 속도를 단축시킬 수 있다.<br>
(물론 update와 upgrade를 미리하면 그만큼 패키지가 다소 무거워지기 때문에 선택사항)<br>
이 외 우분투+경량 패키지에서는 일부 명령어를 지원하지 않는 경우가 있어 모든 머신에서 공통적으로 필요한 경우 미리 설치하자.<br>
>ex. ping 명령어 - iputils-ping, ifconfig 명령어 - net-tools, nslookup 명령어 - dnsutils 등
---

### 3) 커스텀 박스 생성하기
1. vmware로 box를 구성하기 위해서는 베이스가 되는 가상 머신 대부분의 데이터가 필요하다. (virtual Box보다 요구하는게 많다.)
2. VMware 머신이 작동하는 데 꼭 필요한 파일은 **nvram, vmsd, vmx, vmxf 및 vmdk 파일**이다.
3. 대략 캐시 데이터 지우고, 상태 백업 파일을 지우면 되는 수준이다.
   ![image](https://github.com/user-attachments/assets/68571942-dbb8-4e9a-9c5c-b67d8b420825)
4. 추가적으로 [metadata.json](https://developer.hashicorp.com/vagrant/docs/boxes/format)에 대한 생성도 요구되는데, 기본적으로 provider를 포함하면 된다.<br>
     ```json
    {
          "provider": "vmware_desktop"
    }
    ```
    metadata.json 파일은 Vagrant가 Box 파일 내에서 vmx, vmdk의 제공자와 구성에 대해 알려주기 위한 메타데이터 파일이다.
5. 터미널을 이용해 파일이 저장된 경로로 이동한 후 ` tar cvzf "박스 이름.box" ./*` 명령어를 입력해 box 파일로 압축한다.
* 자세한 설명은 [Document Vagrant/Providers/Vmware/](https://developer.hashicorp.com/vagrant/docs/providers/vmware/boxes)를 참고하자.

### 4) Hashcorp Cloud(Vagrant 리포지터리)에 등록하기
위 내용처럼 [Hashicorp Cloud](https://portal.cloud.hashicorp.com/) 에서는 검증된 다양한 box를 제공한다.

단, 공개된 박스 중 필요한 패키지가 없다면 위 단계에서 만들어진 box를 Vagrant Cloud에 업로드 함으로 깃허브처럼 어느 위치에서나 box를 사용할 수 있도록 구성할 수 있다.

![image](https://github.com/user-attachments/assets/3dc155c8-1c55-42fb-b08a-53366ad8e585)

## 2. Vagrant

### 1) Vagrant 설치
생략, [Vagrant 설치 경로](https://developer.hashicorp.com/vagrant/install?product_intent=vagrant)

### 2) Vagrant VMware Plugin 설치

VMware나 Docker 등 Virtual Box가 아닌 다른 프로그램을 이용할 경우 각 프로바이더에 맞는 플러그인 프로그램을 설치하고 적용해야 한다.

1. [윈도우 플러그인 프로그램 설치](https://developer.hashicorp.com/vagrant/install/vmware)
2. vagrant에 플러그인 등록
    ```bash
    vagrant plugin install vagrant-vmware-desktop
    ```
   
### 3) Vagrant로 가상머신 프로비저닝하기
1. vagrant init을 이용해 VagrantFile을 생성하기

    vagrant init 리포지터리명/box명 --box-version 버전명<br>
   `vagrant init swhwang/ubuntu --box-version 0`

   
3. Vagrant 실행하기<br>
    아래와 같이 실행하고 VMware 가상머신이 생성되는 것을 확인한다.

    `Vagrant up --provider vmware_desktop`

> ### 다운로드한 박스를 로컬 Vagrant에 등록하기
> 파일 형태의 Box를 사용하려면 Vagrant에 Box를 등록해야 한다.<br>
> 파일과 함께 앞으로 버전 관리를 위한 이름과 프로비저닝에 사용할 도구(vmware_desktop)을 옵션으로 함께 명시한다.<br>
> `vagrant box add --name "박스이름" "박스파일.box 경로" --provider=vmware_desktop`
---

### 권장) Vagrant Registry 내 배포된 Box(이미지 같은거)를 수정하자
도커 이미지와 마찬가지로 처음부터 끝까지 수동으로 구성하려다 보면 구성적으로나 보안적으로 놓치는 부분이 발생한다.
(~~박스 크기를 최적화 하다 오류가 나서 포기한건 아니다.~~)

+ 실제 운영 환경에 적용할 때는 신뢰할 수 있는 공식 이미지를 이용하자.
1. [Vagrant Cloud - generic/ubuntu2204](https://portal.cloud.hashicorp.com/vagrant/discover/generic/ubuntu2204)에서 최신 버전 박스 확인
2. VagrantFile 정의하기 & `vagrant up`으로 프로비저닝
```VagrantFile
$pre_install = <<-SCRIPT
    echo ">>>> 미러 리포지터리를 카카오로 변경 <<<<"
    sudo sed -i.bak 's|https://mirrors.edge.kernel.org|http://mirror.kakao.com|g' /etc/apt/sources.list
    echo ">>>> 패키지 목록 업데이트 <<<<"
    sudo apt-get update
    echo ">>>> pre-install 완료 <<<<"
SCRIPT

Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    config.vm.box_version = "4.3.12"
    

    config.vm.define "sample" do |sample|
    sample.vm.provider "vmware_desktop" do |v|
        v.vmx['displayname'] = "Sample"
        v.memory = 6144 # 6GB
        v.cpus = 3
        end
    sample.vm.hostname = "sample"
    sample.vm.network "public_network", ip: "dhcp"
    sample.vm.provision "shell", inline: $pre_install
    end
end
```
3. Vagrant Box 패키징 && upload

먼저 `vagrant halt`로 VM을 중지한 후 `vagrant package --output "박스 파일 명.box"`로 패키징한다.

4. box 파일을 외부 저장소에 업로드한다.

위 과정을 거쳐서 만들어진 박스를 리포지터리에 업로드 했다. `box: swhwang/ubuntu version: 1.0`

그나마 generic/ubuntu2204 박스가 다운로드 수도 많고 크기가 1.76 GB로 작아 사용했다.<br>
도커와 다르게 박스 하나 하나가 매우 무겁기 때문에 수정을 최소로 가급적 이미 구성된 것을 개선하는 방향으로 구성하자.<br>
참고로 upgrade를 수행한 후 박스 크기가 3.6GB로 거의 2배가 됐다. 즉, 클라우드를 이용해 박스가 다운로드 되는 시간이 늘어난다.