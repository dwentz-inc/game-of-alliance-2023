#!/bin/bash

sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export TERA_CHAIN_ID=ordos-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "moniker : \e[1m\e[32m$NODENAME\e[0m"
echo -e "wallet  : \e[1m\e[32m$WALLET\e[0m"
echo -e "chain-id: \e[1m\e[32m$TERA_CHAIN_ID\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt list --upgradable && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
ver="1.19" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/terra-money/alliance
cd alliance
git checkout v0.0.1-goa
make build-alliance ACC_PREFIX=ordos
mv build/ordosd $HOME/go/bin/

# config & init
ordosd config chain-id $TERA_CHAIN_ID
ordosd config keyring-backend test
ordosd init $NODENAME --chain-id $TERA_CHAIN_ID

# download genesis
wget -O genesis.json https://raw.githubusercontent.com/terra-money/alliance/v0.0.1-goa/genesis/ordos-1/genesis.json
mv genesis.json ~/.ordos/config

# download addrbok
wget -qO $HOME/.ordos/config/addrbook.json "https://raw.githubusercontent.com/LavenderFive/game-of-alliance-2023/master/addrbook/addrbook-ordos.json"

# set peers and seeds
PEERS=2c66624a7bbecd94e8be4005d0ece19ce284d7c3@54.196.186.174:41356,6ebf0000ee85ff987f1d9de3223d605745736ca9@35.168.16.221:41356,71f96fe3eec96b9501043613a32a5a306a8f656b@goa-seeds.lavenderfive.com:10656
sed -i.bak -e "s/^seeds *=.*/seeds = \"$PEERS\"/" $HOME/.ordos/config/config.toml


# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.ordos/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.ordos/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.ordos/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.ordos/config/app.toml

# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uord\"/" $HOME/.ordos/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.ordos/config/config.toml

# reset
ordosd tendermint unsafe-reset-all --home $HOME/.ordos

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/ordosd.service > /dev/null <<EOF
[Unit]
Description=ordo
After=network-online.target

[Service]
User=$USER
ExecStart=$(which ordosd) start --home $HOME/.ordos
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload 
sudo systemctl enable ordosd 
sudo systemctl restart ordosd

echo '=============== SETUP FINISHED ==================='

