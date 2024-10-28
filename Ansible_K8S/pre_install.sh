#!/bin/bash
echo ">>>> 미러 리포지터리를 카카오로 변경 <<<<"
sudo sed -i.bak 's|https://mirrors.edge.kernel.org|http://mirror.kakao.com|g' /etc/apt/sources.list
echo ">>>> 패키지 목록 업데이트 <<<<"
sudo apt-get update
echo ">>>> pre-install 완료 <<<<"