port = [180, 164, 148, 132]
MAC = [0x1070fd190095, 0x1070fd2fd851, 0x1070fd2fe441, 0x1070fd2fd421]
for worker in range(len(port)):
    bfrt.sample_switch.pipe.Ingress.l2_forward_table.add_with_l2_forward(MAC[worker], port[worker])

bfrt.sample_switch.pipe.Egress.dcqcn.wred.add(0, 0, 125, 2500, 0.01)
# DCQCN
# 0 ~ 10KB, 0 
# 10 ~ 200KB, 0 ~ 0.01
# 200KB ~, 1

for p in port:
    bfrt.port.port.add(p, 'BF_SPEED_100G', 'BF_FEC_TYP_NONE', 4, True, 'PM_AN_FORCE_DISABLE')