#!/bin/bash

sleep 2


echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/terra-money/alliance
cd alliance
git checkout v0.0.1-goa
make build-alliance ACC_PREFIX=atreides
mv build/atreidesd $HOME/go/bin/

# config & init
atreidesd config chain-id atreides-1
atreidesd config keyring-backend test
atreidesd init zetsu --chain-id atreides-1

# download genesis
wget -O genesis.json https://raw.githubusercontent.com/terra-money/alliance/v0.0.1-goa/genesis/atreides-1/genesis.json
mv genesis.json ~/.atreides/config

# download addrbok
wget -qO $HOME/.atreides/config/addrbook.json "https://raw.githubusercontent.com/LavenderFive/game-of-alliance-2023/master/addrbook/addrbook-atreides.json"

# set peers and seeds
PEERS=36b2547e91dbaa1a6196217f25b767a8630fb0b2@54.196.186.174:41456,cd19f4418b3cd10951060aad1c4b4baf82177292@35.168.16.221:41456,d634d42f4f84caa0db7c718353090fd7973e702e@goa-seeds.lavenderfive.com:13656
sed -i.bak -e "s/^seeds *=.*/seeds = \"$PEERS\"/" $HOME/.atreides/config/config.toml


# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.atreides/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.atreides/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.atreides/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.atreides/config/app.toml

# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uatr\"/" $HOME/.atreides/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.atreides/config/config.toml

# reset
atreidesd tendermint unsafe-reset-all --home $HOME/.atreides

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/atreidesd.service > /dev/null <<EOF
[Unit]
Description=atreides
After=network-online.target

[Service]
User=$USER
ExecStart=$(which atreidesd) start --home $HOME/.atreides
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload 
sudo systemctl enable atreidesd 
sudo systemctl restart atreidesd

echo '=============== SETUP FINISHED ==================='
