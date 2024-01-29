port = [180, 164, 148, 132]
MAC = [0x1070fd190095, 0x1070fd2fd851, 0x1070fd2fe441, 0x1070fd2fd421]
multicast_l3_protocols = [0x0800]
for worker in range(len(port)):
    bfrt.traffic_multicast.pipe.Ingress.l2_forward_table.add_with_l2_forward(MAC[worker], port[worker])


# enable multicast for specific protocol
for protocol in multicast_l3_protocols:
    bfrt.traffic_multicast.pipe.Ingress.multicast_table.add_with_do_multicast(protocol)

mgid = 1
node_id = [1, 2, 3, 4]
rid = [1, 2, 3, 4]
# configure multicast group
for i in range(len(port)):
    bfrt.pre.node.add(node_id[i], rid[i], None, [port[i]])
    # L1 node $i with rid $i and port $port[i]

bfrt.pre.mgid.add(mgid, node_id, [False]*len(node_id), [0]*len(node_id))
# multicast group id 1 with L1 node 1~4

# you can multicast to a port multiple times in a multicast group

for p in port:
    bfrt.port.port.add(p, 'BF_SPEED_100G', 'BF_FEC_TYP_RS', 4, True, 'PM_AN_FORCE_DISABLE')