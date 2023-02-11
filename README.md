### game-of-alliance-2023
```
wget -O ordo.sh https://raw.githubusercontent.com/dwentz-inc/game-of-alliance-2023/main/ordo.sh && chmod +x ordo.sh && ./ordo.sh
```
```
source $HOME/.bash_profile
```
Ada 4 chain [lihat disini](https://github.com/terra-money/alliance)

### Informasi node

* cek sync node
```
ordosd status 2>&1 | jq .SyncInfo
```
* cek log node
```
journalctl -fu ordosd -o cat
```
* cek node info
```
ordosd status 2>&1 | jq .NodeInfo
```
* cek validator info
```
ordosd status 2>&1 | jq .ValidatorInfo
```
* cek node id
```
ordosd tendermint show-node-id
```
### Membuat wallet
* wallet baru
```
ordosd keys add $WALLET
```
* recover wallet
```
ordosd keys add $WALLET --recover
```
* list wallet
```
ordosd keys list
```
* hapus wallet
```
ordosd keys delete $WALLET
```
### Simpan informasi wallet
```
ORDO_WALLET_ADDRESS=$(ordosd keys show $WALLET -a)
ORDO_VALOPER_ADDRESS=$(ordosd keys show $WALLET --bech val -a)
echo 'export ORDO_WALLET_ADDRESS='${ORDO_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export ORDO_VALOPER_ADDRESS='${ORDO_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Membuat validator
* cek balance
```
ordosd query bank balances $ORDO_WALLET_ADDRESS
```
* membuat validator
```
ordosd tx staking create-validator \
  --amount 500000000uord \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --identity "F57A71944DDA8C4B" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(ordosd tendermint show-validator) \
  --moniker $NODENAME \
  --fees 500uord \
  --gas auto \
  --chain-id ordos-1
```
* edit validator
```
ordosd tx staking edit-validator \
  --new-moniker="nama-node" \
  --identity="<your_keybase_id>" \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$TERA_CHAIN_ID \
  --from=$WALLET
```
* unjail validator
```
ordosd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$TERA_CHAIN_ID \
  --gas=auto
```
### Voting
```
ordosd tx gov vote 1 yes --from $WALLET --chain-id=$TERA_CHAIN_ID --gees=250uord
```
### Delegasi dan Rewards
* delegasi
```
ordosd tx staking delegate $ORDO_VALOPER_ADDRESS 1000000uord --from=$WALLET --chain-id=$TERA_CHAIN_ID --gas=auto --fees=250uord
```
* withdraw reward
```
ordosd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$TERA_CHAIN_ID --gas=auto --fees=250uord
```
* withdraw reward beserta komisi
```
ordosd tx distribution withdraw-rewards $ORDO_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$TERA_CHAIN_ID --fees=250uord
```
### Hapus node
```
sudo systemctl stop ordosd && \
sudo systemctl disable ordosd && \
rm -rf /etc/systemd/system/ordosd.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf alliance && \
rm -rf ordo.sh && \
rm -rf .ordos && \
rm -rf $(which ordosd)
```
