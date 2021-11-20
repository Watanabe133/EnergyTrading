// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract EnergyTrading {
    //状態変数宣言
    address public owner;                   //オーナーアドレス
    uint256 public ContractPrice;           //約定価格
    uint256 public RecalculateCount;        //再精算の件数

    event DicisionContractPrice(uint256 ContractPrice);     //約定価格決定イベント通知

    // オーナー限定メソッド用の修飾子
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner!");
        _;
    }

    Consumer[] public consumers;            //可変長配列宣言
    //consumer構造体
    struct Consumer {
        address consumer;                   //consumerアドレス
        uint256 kwh;                        //購入電力量[kwh]
        uint256 value;                      //購入価格
        uint256 sum;                        //合計電力量[kwh]
    }

    Prosumer[] public prosumers;            //可変長配列宣言
    //prosumer構造体
    struct Prosumer {
        address prosumer;                   //prosumerアドレス
        uint256 kwh;                        //売却電力量[kwh]
        uint256 value;                      //売却価格
        uint256 sum;                        //合計電力量[kwh]
    }

    //コンストラクタ
    constructor() {
        ContractPrice = 0;
        RecalculateCount = 0;
        owner = msg.sender;
    }

    //consumerの追加
    function pushConsumer(address consumer, uint256 kwh, uint256 value) public returns(uint256 IndexNumber) {
        consumers.push(Consumer({
        consumer: consumer,
        kwh: kwh,
        value: value,
        sum: kwh
        }));
        return(consumers.length - 1);
    }

    //consumerの変更
    function editConsumer(address aconsumer, uint256 IndexNumber, uint256 kwh, uint256 value) public {
        if(IndexNumber < consumers.length) {
            consumers[IndexNumber].consumer = aconsumer;
            consumers[IndexNumber].kwh = kwh;
            consumers[IndexNumber].value = value;
            consumers[IndexNumber].sum = kwh;
        }
    }

    //prosumerの追加
    function pushProsumer(address prosumer, uint256 kwh, uint256 value) public returns(uint256 IndexNumber) {
        prosumers.push(Prosumer({
        prosumer: prosumer,
        kwh: kwh,
        value: value,
        sum: kwh
        }));
        return(prosumers.length - 1);
    }

    //prosumerの変更
    function editProsumer(address aprosumer, uint256 IndexNumber, uint256 kwh, uint256 value) public {
        if(IndexNumber < prosumers.length) {
            prosumers[IndexNumber].prosumer = aprosumer;
            prosumers[IndexNumber].kwh = kwh;
            prosumers[IndexNumber].value = value;
            prosumers[IndexNumber].sum = kwh;
        }
    }

    //約定処理
    function Agreement() public onlyOwner returns(uint contractprice) {
        //consumerの価格を降順に並べ替え
        address tmpc;
        uint256 tmpk;
        uint256 tmpv;
        uint256 tmps;
        for(uint256 i = 0; i < consumers.length; i++) {
            for(uint256 j = (consumers.length - 1); j > i; j--) {
                if(consumers[j].value > consumers[j-1].value) {
                    tmpc = consumers[j].consumer;
                    tmpk = consumers[j].kwh;
                    tmpv = consumers[j].value;
                    tmps = consumers[j].sum;
                    consumers[j].consumer = consumers[j-1].consumer;
                    consumers[j].kwh = consumers[j-1].kwh;
                    consumers[j].value = consumers[j-1].value;
                    consumers[j].sum = consumers[j-1].sum;
                    consumers[j-1].consumer = tmpc;
                    consumers[j-1].kwh = tmpk;
                    consumers[j-1].value = tmpv;
                    consumers[j-1].sum = tmps;
                }
            }
        }

        //板全体の合計電力量の計算
        for(uint256 k = 1; k < consumers.length; k++) {
            consumers[k].sum = consumers[k].kwh + consumers[k-1].sum;
        }

        //prosumerの価格を昇順に並べ替え
        address tmpp;
        uint256 tmpw;
        uint256 tmpm;
        uint256 tmpt;
        for(uint256 x = 0; x < prosumers.length; x++) {
            for(uint256 y = (prosumers.length - 1); y > x; y--) {
                if(prosumers[y].value < prosumers[y-1].value) {
                    tmpp = prosumers[y].prosumer;
                    tmpw = prosumers[y].kwh;
                    tmpm = prosumers[y].value;
                    tmpt = prosumers[y].sum;
                    prosumers[y].prosumer = prosumers[y-1].prosumer;
                    prosumers[y].kwh = prosumers[y-1].kwh;
                    prosumers[y].value = prosumers[y-1].value;
                    prosumers[y].sum = prosumers[y-1].sum;
                    prosumers[y-1].prosumer = tmpp;
                    prosumers[y-1].kwh = tmpw;
                    prosumers[y-1].value = tmpm;
                    prosumers[y-1].sum = tmpt;
                }
            }
        }

        //板全体の合計電力量の計算
        for(uint256 z = 1; z < prosumers.length; z++) {
            prosumers[z].sum = prosumers[z].kwh + prosumers[z-1].sum;
        }

        //約定価格決定
        for(uint256 s = 0; s < consumers.length; ) {
            for(uint256 m = 0; m < prosumers.length; ) {
                if(consumers[s].value > prosumers[m].value) {
                    if(consumers[s].sum <= prosumers[m].sum) {
                        s++;
                    } else {
                        m++;
                    }
                } else {
                    ContractPrice = prosumers[m].value;         //約定価格
                    emit DicisionContractPrice(ContractPrice);
                    return ContractPrice;
                }
            }
        }
    }


    //購入可能か
    function AvailableBuyer(address confirmer) public view returns(bool availableBuyer, uint256 IndexNumber) {
        for(uint256 t = 0; t < consumers.length; ) {
            if((consumers[t].consumer == confirmer) && (consumers[t].value >= ContractPrice)) {
                return(true, t);
            } else {
                t++;
            }
        }
    }

    //売却可能か
    function AvailableSeller(address confirmer) public view returns(bool availableSeller, uint256 IndexNumber) {
        for(uint256 u = 0; u < prosumers.length; ) {
            if((prosumers[u].prosumer == confirmer) && (prosumers[u].value <= ContractPrice)) {
                return(true, u);
            } else {
                u++;
            }
        }
    }

    //再精算プログラム
    function Recalculate(address applicant, uint256 trueEnergy, uint256 insufficientImbalanceRate, uint256 surplusImbalanceRate) public returns(uint256 PenaltyETH, uint256 IndexNumber) {
        uint256 insufficientImbalance;
        uint256 surplusImbalance;
        uint256 InsufficientImbalanceRate = insufficientImbalanceRate;
        uint256 SurplusImbalanceRate = surplusImbalanceRate;
        for(uint256 o = 0; o < consumers.length; ) {
            if((consumers[o].consumer == applicant) && (consumers[o].value >= ContractPrice)) {
                if(trueEnergy < consumers[o].kwh) {
                    insufficientImbalance = 100 - ((trueEnergy * 100) / consumers[o].kwh);
                    if(insufficientImbalance > InsufficientImbalanceRate) {
                        RecalculateCount++;
                        return(insufficientImbalance, o);
                    } else {
                        revert("unnecessary recalculate");
                    }
                } else {
                    surplusImbalance = ((trueEnergy * 100) / consumers[o].kwh) - 100;
                    if(surplusImbalance > SurplusImbalanceRate) {
                        RecalculateCount++;
                        return(surplusImbalance, o);
                    } else {
                        revert("unnecessary recalculate");
                    }
                }
            } else if((consumers[o].consumer == applicant) && (consumers[o].value < ContractPrice)) {
                revert("Not stakeholder");
            } else {
                o++;
            }
        }
    }
}