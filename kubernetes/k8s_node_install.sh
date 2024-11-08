#!/bin/bash
echo ">>>> 패키지 목록 업데이트 <<<<"
sudo apt-get update && sudo apt-get upgrade -y
echo ">>>> 쿠버네티스 리포지터리 추가 용 패키지 설치 <<<"
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
echo ">>>> 스왑 메모리 비활성화 <<<<"
sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab
echo "======================================================================="
echo ">> 주의! 아래 공개 키 다운과 리포지터리 경로는 최신화가 안 될 수 있음!! 중간에 오류가 발생하면 대부분 여기!"
echo ">>>> 구글 클라우드 공개 사이닝 키 다운 <<<<"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo ">>>> 쿠버네티스 apt 리포지터리 추가<<<<"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo ">>>> 쿠버네티스 apt 리포지터리 업데이트 <<<<"
sudo apt-get update
echo "======================================================================="
echo ">>>> kubelet, kubeadm, kubectl 설치 및 업데이트 제외(패키지 고정) <<<<"
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo ">>> 설치된 패키지 버전 확인 <<<"
sudo kubeadm version
sudo kubelet --version
sudo kubectl version --client
echo "======================================================================="
echo ">>>> 컨테이너 런타임 인터페이스:Containerd 설치 <<<<"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get -y install containerd
echo ">>>> Containerd 환경 설정 <<<<"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
KUBELET_CONFIG="/var/lib/kubelet/config.yaml"
CONTAINERD_CONFIG="/etc/containerd/config.toml"
sed -i 's|^containerRuntimeEndpoint:.*|containerRuntimeEndpoint: "unix:///var/run/containerd/containerd.sock"|' "$KUBELET_CONFIG"
sudo sed -i 's/containerRuntimeEndpoint: ""/containerRuntimeEndpoint: "unix:\/\/\/var\/run\/containerd\/containerd.sock"/' "$KUBELET_CONFIG"
sed -i 's|SystemdCgroup = .*|SystemdCgroup = true|' "$CONTAINERD_CONFIG"
sudo systemctl restart containerd
sudo systemctl restart kubelet
echo ">>>> 커널 모듈 활성화 <<<<"
sudo modprobe overlay
sudo modprobe br_netfilter
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/kubernetes.conf
echo ">>>> 커널 매개변수 설정 <<<<"
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
