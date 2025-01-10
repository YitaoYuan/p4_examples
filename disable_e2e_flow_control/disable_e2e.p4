/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "std_header.p4"

typedef bit<9> egress_spec_t;
// typedef bit<48> mac_addr_t;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

struct headers {
    eth_t eth;
    ip_t ip;
    udp_t udp;
    bth_t bth;
    aeth_t aeth;
}

struct port_metadata_t {
    bit<16> unused; 
}

struct metadata {
    port_metadata_t port_metadata;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser IngressParser(packet_in packet,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_md) {

    state start {
        packet.extract(ig_md);
        transition select(ig_md.resubmit_flag) {
            0 : parse_port_metadata;
        }
    }

    state parse_port_metadata {
        meta.port_metadata = port_metadata_unpack<port_metadata_t>(packet);
        transition parse_eth;
    }

    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.protocol) {
            IP_PROTOCOL: parse_ip;
            default: accept;
        }
    }

    state parse_ip{
        packet.extract(hdr.ip);
        transition select(hdr.ip.protocol) {
            UDP_PROTOCOL: parse_udp;
            default: accept;
        }
    }

    state parse_udp{
        packet.extract(hdr.udp);
        transition select(hdr.udp.dport) {
            RDMA_DPORT: parse_bth;
            default: accept;
        }
    }

    state parse_bth{
        packet.extract(hdr.bth);
        transition select(hdr.bth.opcode) {
            RDMA_OP_ACK: parse_aeth;
            default: accept;
        }
    }

    state parse_aeth{
        packet.extract(hdr.aeth);
        transition accept;
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control Ingress(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    
    action drop() {
        ig_dprs_md.drop_ctl = 0x1;
    }

    action l2_forward(PortId_t port) {// 9 bit
        ig_dprs_md.drop_ctl = 0;
        ig_tm_md.ucast_egress_port = port;
        // In doc of TNA, 192 is CPU PCIE port and 64~67 is CPU eth ports for 2-pipe TF1
    }

    action l2_multicast(MulticastGroupId_t group) {// 16 bit
        ig_dprs_md.drop_ctl = 0;
        ig_tm_md.mcast_grp_a = group;
    }

    // action l2_forward_copy_to_cpu(bit<9> port) { // useless
    //     ig_dprs_md.drop_ctl = 0;
    //     ig_tm_md.ucast_egress_port = port;
    //     ig_tm_md.copy_to_cpu = 1;
    // }

    table l2_forward_table{
        key = {
            hdr.eth.dmac: exact;
        }
        actions = {
            l2_forward;
            l2_multicast;
            // l2_forward_copy_to_cpu;
            drop;
        }
        size = 32;
        default_action = drop();
    }

    apply {
        l2_forward_table.apply();

        if(hdr.aeth.isValid())
            if(hdr.aeth.syndrome_msn[31:29] == 0) // ACK packet
                hdr.aeth.syndrome_msn[31:24] = 8w0b00011111; // disable end-to-end flow control
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control IngressDeparser(
        packet_out packet,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply{
        packet.emit(hdr);
    }
}

parser EgressParser(packet_in packet,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_md) {
    state start {
        packet.extract(eg_md);
        transition parse_eth;
    }

    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.protocol) {
            0x0800: parse_ip;
            default: accept;
        }
    }

    state parse_ip{
        packet.extract(hdr.ip);
        transition accept;
    }
}

control dcqcn(
    inout headers hdr,
    in egress_intrinsic_metadata_t eg_md) {

    Wred<bit<19>, bit<32>>(32w1, 8w1, 8w0) wred;
    apply {
        if(hdr.ip.isValid()) {
            if(hdr.ip.dscp_ecn[1:0] == 0) { // Using "!=" and "&&" sometimes causes BUG
            }
            else {
                bit<8> drop_flag = wred.execute(eg_md.deq_qdepth, 0);
                if(drop_flag == 1) hdr.ip.dscp_ecn[1:0] = 3;
            }
        }
    }
}

control Egress(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    apply { 
        dcqcn.apply(hdr, eg_md);
    }
}

control EgressChecksum(inout headers hdr) {
    Checksum() csum;
    apply{
        hdr.ip.checksum = csum.update({
            hdr.ip.ver_hl,
            hdr.ip.dscp_ecn,
            hdr.ip.length,
            hdr.ip.id,
            hdr.ip.flag_offset,
            hdr.ip.ttl,
            hdr.ip.protocol,
            hdr.ip.sip,
            hdr.ip.dip
        });
    }
}

control EgressDeparser(packet_out packet,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_dprs_md) {
    
    apply { 
        EgressChecksum.apply(hdr);
        packet.emit(hdr);
    }
}

Pipeline(IngressParser(), Ingress(), IngressDeparser(), EgressParser(), Egress(), EgressDeparser()) pipe;

Switch(pipe) main;
