port = [0, 180, 164, 148, 132]
MAC = [0, 0x1070fd190095, 0x1070fd2fd851, 0x1070fd2fe441, 0x1070fd2fd421]
for worker in range(1, len(port)):
    bfrt.sample_switch.pipe.Ingress.l2_forward_table.add_with_l2_forward(MAC[worker], port[worker])
