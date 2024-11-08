* 참고자료 :
* https://jbground.tistory.com/107
* https://www.inflearn.com/community/questions/888659/%EC%BF%A0%EB%B2%84%EB%84%A4%ED%8B%B0%EC%8A%A4-%EC%84%A4%EC%B9%98%ED%95%A0-%EB%95%8C-%EC%97%90%EB%9F%AC%EB%82%A9%EB%8B%88%EB%8B%A4-%ED%95%B4%EA%B2%B0-%EB%B0%A9%EB%B2%95-%EA%B3%B5%EC%9C%A0%ED%95%A9%EB%8B%88%EB%8B%A4-23-05-30-%EA%B8%B0%EC%A4%80?srsltid=AfmBOoq-ni2L_ZSWJdHFat_4PPpRPNOTFEeISgs9iaVLh3TL5KpEcj7G
* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
* https://littlemobs.com/blog/kubernetes-package-repository-deprecation/
#1단계: 각 서버 준비 - 루트 계정으로 진행

종속성 업데이트 및 설치
각 서버에서 다음 명령을 실행하여 패키지 인덱스를 업데이트하고 필요한 패키지를 설치합니다.

```
apt update
apt upgrade -y
apt install -y apt-transport-https ca-certificates curl software-properties-common
```

#2단계: 스왑 비활성화

Kubernetes에서는 스왑을 비활성화해야 합니다. 스왑을 즉시 끄려면 각 서버에서 다음 명령을 실행하십시오.
```sudo swapoff -a```

#3단계: 커널 모듈 활성화
각 서버에서 Kubernetes에 필요한 커널 모듈을 로드
```
modprobe overlay
modprobe br_netfilter
echo -e "overlay\nbr_netfilter" | tee /etc/modules-load.d/kubernetes.conf
```

#4단계: 커널 매개변수 설정

Kubernetes 네트워킹을 위한 sysctl 매개변수를 구성
```
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

#5단계: 컨테이너 런타임 설치
쿠버네티스의 권장 런타임은 `containerd`
```
apt install -y containerd
```

#6단계: 컨테이너 구성
Containerd에 대한 기본 구성 파일 생성
```
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

#7단계: 컨테이너 재시작
```
systemctl restart containerd
systemctl enable containerd
```
---
#8단계: 패키지 설치
> # 2. 구글 클라우드의 공개 사이닝 키를 다운로드 한다.
> curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

> # 3. 쿠버네티스 apt 리포지터리를 추가한다.
> echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
> curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

> # 4. apt 패키지 색인을 업데이트하고, kubelet, kubeadm, kubectl을 설치하고 해당 버전을 고정한다.
> ```sudo apt-get update
> sudo apt-get install -y kubelet kubeadm kubectl
> sudo apt-mark hold kubelet kubeadm kubectl```
---
#8단계 : kubeadm 소스코드 설치 (소스코드 설치 방식)
> apt를 이용해 설치를 하다보니 kubeadm과 kubelet의 패키지 버전으로 인한 호환성 문제가 발견되었다.
> 버전 통합을 위해 소스코드 설치 방식을 사용하였다.
```
wget https://github.com/kubernetes/kubernetes/archive/refs/tags/v1.31.2.tar.gz
tar -xzvf v1.31.2.tar.gz
cd kubernetes-1.31.2
```
#9단계: 빌드 환경 설정
```
sudo apt update
sudo apt install -y golang make
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```
#10단계: 컴포넌트 빌드 & 바이너리 파일을 환경변수 경로로 이동
```
make all WHAT=cmd/kubeadm && make all WHAT=cmd/kubelet && make all WHAT=cmd/kubectl
sudo cp _output/bin/kubeadm /usr/local/bin/ && sudo cp _output/bin/kubelet /usr/local/bin/ && sudo cp _output/bin/kubectl /usr/local/bin/
```
#11단계: 각 구성요소의 버전이 올바르게 설치 되었는지 확인한다.
```
kubeadm version
kubelet --version
kubectl version --client

```
#12단계: 소스코드 방식은 서비스 구성도 수동으로 해야 한다.
`sudo nano /etc/systemd/system/kubelet.service`에 아래 내용을 추가하자
```ini
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```
#13단계: 서비스 데몬 리로드 및 활성화 후 상태 확인
```
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet
sudo kubeadm config images pull
sudo systemctl status kubelet
```
#14단계: kubeadm init으로 클러스터 초기화 (서버 실행))
```
sudo systemctl kubeadm init
```
#15단계: kubeadm init 에러 트러블슈팅
모든 설정이 끝났더라도 컨테이너 런타임에 따라 몇가지 오류가 발생할 수 있다.
1. kubelet 서비스 상태 확인 & 로그 데이터 확인
   ```
   sudo systemctl status kubelet
   sudo journalctl -xeu kubelet
   ```
2. cgroup 설정 확인 및 서비스 재시작 
   ```
   sudo nano /var/lib/kubelet/config.yaml
       => 아래 이 내용이 작성되어 있나 찾아보기
         cgroupDriver: systemd
   sudo nano /etc/containerd/config.toml
       => Systemd가 Cgroup을 이용할 수 있도록 true로 설정, 아래 내용이 포함
       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true
       containerRuntimeEndpoint: "unix:///run/containerd/containerd.sock"
   sudo systemctl restart containerd
   sudo systemctl restart kubelet
   sudo systemctl status kubelet
   ```
   
