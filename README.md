# P4_examples

## 组成

### sample_switch

二层静态转发交换机

### traffic_mirror

网络抓包器，可将网络中所有包复制到指定端口，用于网络监测

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


