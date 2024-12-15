# Pop-OS has its own way to prioritize the package repo to install from, this should be changed to allow to install the latest nvidia version https://github.com/NVIDIA/nvidia-container-toolkit/issues/23#issuecomment-1149806160
sudo vim /etc/apt/preferences.d/nvidia-docker-pin-1002
# Package: *
# Pin: origin nvidia.github.io
# Pin-Priority: 1002

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker
# Needs nivida-container-toolkit>=1.14.0-rc2 for containerd support (https://github.com/NVIDIA/nvidia-docker/issues/1781#issuecomment-1690729112)
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd

-----
# Deploy nvidia-device-plugin
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace