# P2P電力取引
## 環境構築
### go-Ethereum(geth)のインストール
#### Ubuntu
```sudo apt update```

```sudo apt install ethereum```

#### HomeBrew
```brew tap ethereum/ethereum```

```brew install ethereum```

### gethのバージョン確認
```geth --version```
or
```brew info ethereum```

### gethをプライベートネットワークで起動する
#### genesis.jsonを作成
```mkdir private_net```
で任意のディレクトリを作成する
```user/private_net```
下に

```genesis.json```
というJSONファイルを作成

#### genesisブロックの初期化
```geth --datadir user/private_net init user/private_net/genesis.json```
を実行しgenesisブロックを初期化

#### gethの起動
```geth --networkid 15 --nodiscover --datadir user/private_net console 2>> user/private_net/geth_err.log```
でgethを起動する

--networkidはgenesis.json内のchainIdと同一のものにする
