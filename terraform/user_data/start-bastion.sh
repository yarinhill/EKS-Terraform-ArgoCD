#!/bin/bash -xe
# This Script Starts a Bastion Instance 
sudo yum update -y
sudo yum install jq wget tar -y
mkdir -p /home/${remote_user}/bin/
touch /home/${remote_user}/bin/find_servers
cat <<EOF > /home/${remote_user}/bin/find_servers
#!/bin/bash
aws ec2 describe-instances --region ${region-master} | jq .Reservations[].Instances[] | jq 'select(.Tags[].Value=="${deploy-name}-eks-node-group"  )' | jq '{"eks-node": .NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress}'
EOF
chmod +x /home/${remote_user}/bin/find_servers
chmod 600 /home/${remote_user}/.ssh/id_rsa

ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Download and install eksctl
sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_$ARCH.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Download and install Node Exporter
LATEST=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r .tag_name)
VERSION=$(echo "$LATEST" | sed 's/v//')
wget https://github.com/prometheus/node_exporter/releases/download/$LATEST/node_exporter-$VERSION.linux-$ARCH.tar.gz -P /home/${remote_user}/
tar xvzf /home/${remote_user}/node_exporter-$VERSION.linux-$ARCH.tar.gz -C /home/${remote_user}/
sudo cp /home/${remote_user}/node_exporter-$VERSION.linux-$ARCH/node_exporter /usr/bin/
sudo useradd -rs /bin/false node_exporter
rm -rf /home/${remote_user}/node_exporter-$VERSION.linux-$ARCH.tar.gz
rm -rf /tmp/eksctl_Linux_$ARCH.tar.gz

# Create and enable Node Exporter service
sudo tee /etc/systemd/system/node_exporter.service << EOF 
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/bin/node_exporter --collector.systemd
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

#Create Secure Tunnel Service
sudo tee /etc/systemd/system/secure-tunnel@.service << EOF
[Unit]
Description=Setup a secure tunnel to %I
After=network.target
[Service]
Environment="LOCAL_ADDR=localhost"
EnvironmentFile=/etc/default/secure-tunnel@%i
ExecStart=/usr/bin/ssh -vvv -i /home/ec2-user/.ssh/id_rsa -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/home/ec2-user/.ssh/known_hosts -L $${LOCAL_ADDR}:$${LOCAL_PORT}:$${REMOTE_ADDRESS}:$${REMOTE_PORT} ec2-user@$${TARGET}
# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=5
Restart=always
[Install]
WantedBy=multi-user.target
EOF
