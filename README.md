# P4_examples

## 组成

### sample_switch

二层静态转发交换机

### sample_switch_red_ecn

RED-ECN，也可以称作DCQCN。
相比于sample_switch，将RDMA二对一incast流量的丢包率从1e-3级别降低到1e-5级别。
对TCP也生效。
推荐默认使用sample_switch_red_ecn

### traffic_mirror

网络抓包器，可将网络中所有包复制到指定端口，用于网络监测

### traffic_multicast

广播示例

## 使用

以sample_switch为例

### 编译

```
./compile.sh ./sample_switch/sample_switch.p4 ./sample_switch/build
```

### 运行

```
./run.sh sample_switch ./sample_switch/bfrt.py
```

### 停止

```
./kill.sh sample_switch
```

https://github.com/YitaoYuan/p4_examples