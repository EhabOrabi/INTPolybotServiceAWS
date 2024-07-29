#!/bin/bash

#Update and install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg

# Create the keyrings directory and add Docker's GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's official repository to APT sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt-get install awscli

# Get the region (modify this part as needed to get the region from your source)
region=$(aws configure get region 2>/dev/null)
# Check if the region is eu-west-3 and run the corresponding command

if [ "$region" == "eu-west-3" ]; then
   # need to run container for paris
   echo "Region is eu-west-3, running command..."
   sudo docker pull ehab215/polybot_region.eu-west-3
   sudo docker run --name polybot -p 8443:8443 ehab215/yolo5_region_eu-west-3:latest
else
  # need to run container for Ohio
  echo "Region is not eu-west-3, running another command..."
  sudo docker pull ehab215/yolo5_region.us-east-2:latest
  sudo docker run --name polybot -p 8443:8443 ehab215/yolo5_region.us-east-2:latest
fi
