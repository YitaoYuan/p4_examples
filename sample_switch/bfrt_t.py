def Namespace():
    # 10.0.0.1~9 10.0.0.20~21
    pcie_port = 192
    pcie_mac = 0x000200000300
    port = [24, 16, 32, 40, 4, 0, 8, 20, 28, 44, 60, pcie_port]
    MAC = [0xb8599f1d04f2, 0xb8599f0b3072, 0x98039b034650, 0xb8599f020d14, \
        0xb8599fb02d50, 0xb8599fb02bb0, 0xb8599fb02bb8, 0xb8599fb02d18, \
        0xb8599fb02d58, 0x0c42a17ab668, 0x0c42a17aca28, pcie_mac]
    # In doc of TNA, 192 is CPU PCIE port and 64~67 is CPU Ethernet ports for 2-pipe TF1
    # 0x000200000300 is the MAC address of bf_pci0, it may not always be this value
    # And, I found that copy_to_cpu not need to be set if we use port 192, so copy_to_cpu is useless ?

    for worker in range(len(port)):
        bfrt.sample_switch.pipe.Ingress.l2_forward_table.add_with_l2_forward(MAC[worker], port[worker])

    bfrt.sample_switch.pipe.Egress.dcqcn.wred.add(0, 0, 125, 2500, 0.01)
    # DCQCN
    # 0 ~ 10KB, 0 
    # 10 ~ 200KB, 0 ~ 0.01
    # 200KB ~, 1

    node_list = []

    for index, p in enumerate(port):
        if p == pcie_port: # this port do not need to be added, and add it will cause error
            continue
        bfrt.port.port.add(p, 'BF_SPEED_100G', 'BF_FEC_TYP_RS', 4, True, 'PM_AN_FORCE_DISABLE')
        node_id = index + 1
        node_list.append(node_id)
        bfrt.pre.node.add(node_id, 0, None, [p]) # node_id, rid, lag_id, dev_port

    mgid = 1 
    bfrt.pre.mgid.add(mgid, node_list, [False] * len(node_list), [0] * len(node_list)) # mgid, node_id, L1_XID_VALID, L1_XID

    bfrt.sample_switch.pipe.Ingress.l2_forward_table.add_with_l2_multicast(0xffffffffffff, mgid)

Namespace()