# fabric_test
## 前提
### パスを通す
```sh
export PATH="$PATH:/home/yoshitaka/fabric/fabric-samples/bin"
```
### コマンド実行場所
基本docker-compose.yamlと同階層

## CA container 立ち上げ
### TLS CA
```sh
docker compose up ca_tls 
```

config生成＆adminのenroll
```sh
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/tlsca/tls-cert.pem 
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/tlsca/admin
fabric-ca-client enroll -d -u https://admin:adminpw@localhost:8054
```
peer1-org1とorderer1-ordererOrgのregister
```sh
fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://localhost:8054
fabric-ca-client register -d --id.name orderer1-ordererOrg --id.secret ordererPW --id.type orderer -u https://localhost:8054
```

### CA Orderer
```sh
docker compose up ca_orderer
```

```sh
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/ordererOrg/ca/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrg/ca/admin
fabric-ca-client enroll -d -u https://admin:adminpw@localhost:9054
fabric-ca-client register -d --id.name orderer1-ordererOrg --id.secret ordererpw --id.type orderer -u https://localhost:9054
fabric-ca-client register -d --id.name admin-ordererOrg --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://localhost:9054
```


### CA Org1
```sh
docker compose up ca_org1
```

```sh
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/org1/ca/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/org1/ca/admin
fabric-ca-client enroll -d -u https://admin:adminpw@localhost:7054
fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://localhost:7054
fabric-ca-client register -d --id.name admin-org1 --id.secret org1AdminPW --id.type admin -u https://localhost:7054
fabric-ca-client register -d --id.name user-org1 --id.secret org1UserPW --id.type user -u https://localhost:7054
```

## Peer1-Org1の立ち上げ
### Peer1-Org1起動準備
Org1 CAの暗号マテリアルの移動
```sh
mkdir -p ${PWD}/organizations/org1/peer1/assets/ca/
cp ${PWD}/organizations/org1/ca/ca-cert.pem ${PWD}/organizations/org1/peer1/assets/ca/
```
Org1 CAでenroll
```sh
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/org1/peer1/assets/ca/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@localhost:7054
```
TLS CAの暗号マテリアルの移動
```sh
mkdir -p ${PWD}/organizations/org1/peer1/assets/tlsca/
cp ${PWD}/organizations/tlsca/tls-cert.pem ${PWD}/organizations/org1/peer1/assets/tlsca/
# cp ${PWD}/organizations/tlsca/ca-cert.pem ${PWD}/organizations/org1/peer1/assets/tlsca/
```
TLS CAでenroll
```sh
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/org1/peer1/assets/tlsca/tls-cert.pem
fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@localhost:8054 --enrollment.profile tls --csr.hosts localhost
```

### Adminのenroll
Org1 CAでadminのenroll
```sh
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/org1/peer1/assets/ca/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin:adminpw@localhost:7054
```
admincertsのディレクトリの作成
```sh
mkdir ${PWD}/organizations/org1/peer1/msp/admincerts
cp ${PWD}/organizations/org1/admin/msp/signcerts/cert.pem ${PWD}/organizations/org1/peer1/msp/admincerts/org1-admin-cert.pem
```

### Peer1の起動
```sh
docker compose up peer1_org1
```

## Ordererの起動
### ordererOrgのCAへ登録
ordererOrgの公開鍵取得
```sh
mkdir -p ${PWD}/organizations/ordererOrg/orderer/assets/ca/
cp ${PWD}/organizations/ordererOrg/ca/ca-cert.pem ${PWD}/organizations/ordererOrg/orderer/assets/ca/org0-ca-cert.pem
```
ordererOrg CAへenroll
```sh
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrg/orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/ordererOrg/orderer/assets/ca/org0-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer1-ordererOrg:ordererpw@localhost:9054
```

### TLS CAへ登録
TLS CAの公開鍵取得
```sh
mkdir -p ${PWD}/organizations/ordererOrg/orderer/assets/tlsca/
cp ${PWD}/organizations/tlsca/tls-cert.pem ${PWD}/organizations/ordererOrg/orderer/assets/tlsca/tls-ca-cert.pem
```
TLS CAへenroll
```sh
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/ordererOrg/orderer/assets/tlsca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer1-ordererOrg:ordererPW@localhost:8054 --enrollment.profile tls --csr.hosts localhost
```

### ordererOrg のAdmin登録
ordererOrgのCAへAdminのenroll
```sh
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrg/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/ordererOrg/orderer/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-ordererOrg:org0adminpw@localhost:9054
```
admincerts mspフォルダの作成、認証情報移動
```sh
mkdir ${PWD}/organizations/ordererOrg/orderer/msp/admincerts
cp ${PWD}/organizations/ordererOrg/admin/msp/signcerts/cert.pem ${PWD}/organizations/ordererOrg/orderer/msp/admincerts/orderer-admin-cert.pem
```

### GenesisBlockの作成

```sh
configtxgen -profile ChannelUsingRaft -outputBlock ${PWD}/organizations/ordererOrg/orderer/genesis.block -channelID mychannel
```

### orderer1_ordererOrgの起動

```sh
docker compose up orderer_ordererOrg
```

## Channel の作成
### osnadminでchannelを作成
```sh
export OSN_TLS_CA_ROOT_CERT=/home/yoshitaka/fabric/git/organizations/tlsca/ca-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=./organizations/ordererOrg/orderer/tls-msp/signcerts/cert.pem
export ORDERER_ADMIN_TLS_PRIVATE_KEY=./organizations/ordererOrg/orderer/tls-msp/keystore/key.pem

osnadmin channel join --channelID mychannel  --config-block ./organizations/ordererOrg/orderer/genesis.block -o localhost:7053 --client-cert $ADMIN_TLS_SIGN_CERT --client-key $ADMIN_TLS_PRIVATE_KEY --ca-file $OSN_TLS_CA_ROOT_CERT 
```




草案
・CAコンテナ立ち上げ
・書くロールregister（localhost）
・enroll
・configtx.gen
・
