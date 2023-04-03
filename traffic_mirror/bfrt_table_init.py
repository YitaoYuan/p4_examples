port = [0, 180, 164, 148, 132]
MAC = [0, 0x1070fd190095, 0x1070fd2fd851, 0x1070fd2fe441, 0x1070fd2fd421]
mirror_port_id = 4
mirror_session_id = 123 # defined in p4
mirror_l3_protocols = [0x0800]
for worker in range(1, len(port)):
    bfrt.traffic_mirror.pipe.Ingress.l2_forward_table.add_with_l2_forward(MAC[worker], port[worker])

# enable mirror
bfrt.mirror.cfg.add_with_normal(mirror_session_id, True, "INGRESS", port[mirror_port_id], True)

# enable mirror for specific protocol
for protocol in mirror_l3_protocols:
    bfrt.traffic_mirror.pipe.Ingress.mirror_filter.add_with_do_mirror(protocol)