/* -*- P4_16 -*- */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

typedef bit<9>  egress_spec_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ip4_addr_t;
typedef bit<16> port_t;
typedef bit<16> checksum_t;

const bit<8>  TCP_PROTOCOL = 0x06;
const bit<8>  UDP_PROTOCOL = 0x11;

const bit<16> TYPE_IPV4 = 0x800;
const MirrorType_t MY_MIRROR_TYPE = 1;
const MirrorId_t MY_MIRROR_ID = 123;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>   ether_type;
}

struct headers {
    ethernet_t ethernet;
}

struct port_metadata_t { // up to 64 bits
    bit<16> unused; 
}

struct ingress_metadata {
    port_metadata_t port_metadata;
    MirrorId_t mirror_id;
}

struct egress_metadata {

}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser IngressParser(packet_in packet,
               out headers hdr,
               out ingress_metadata md,
               out ingress_intrinsic_metadata_t ig_intr_md) {


    state start {
        packet.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            0 : parse_port_metadata;
        }
    }

    state parse_port_metadata {
        md.port_metadata = port_metadata_unpack<port_metadata_t>(packet);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control Ingress(
        inout headers hdr,
        inout ingress_metadata md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_ps_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dps_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action drop() {
        ig_dps_md.drop_ctl = 0x1;
    }

    action l2_forward(bit<9> port) {
        ig_dps_md.drop_ctl = 0;
        ig_tm_md.ucast_egress_port = port;
    }

    table l2_forward_table{
        key = {
            hdr.ethernet.dst_addr: exact;
        }
        actions = {
            l2_forward;
            drop;
        }
        size = 32;
        default_action = drop();
    }

    action do_multicast() {
        ig_tm_md.mcast_grp_a = 1;// mcast_grp_a has a valid bit, but we still don't use 0.
    }

    table multicast_table{
        key = {
            hdr.ethernet.ether_type: exact;
        }
        actions = {
            do_multicast;
            NoAction;
        }
        size = 32;
        default_action = NoAction();
    }

    apply {
        // on default, drop the packet if ig_intr_prsr_md!=0
        l2_forward_table.apply();
        multicast_table.apply();
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control IngressDeparser(
        packet_out packet,
        inout headers hdr,
        in ingress_metadata md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dps_md) {
    
    apply{
        packet.emit(hdr);
    }
}

parser EgressParser(packet_in packet,
               out headers hdr,
               out egress_metadata md,
               out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        packet.extract(eg_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control Egress(
        inout headers hdr,
        inout egress_metadata md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_ps_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dps_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_op_md) {

    apply { 
        if(eg_intr_md.egress_rid != 0) { // not a multicast packet
            hdr.ethernet.src_addr[15:0] = eg_intr_md.egress_rid; // mark the packet 
            hdr.ethernet.dst_addr[15:0] = eg_intr_md.egress_rid;
        }
    }
}

control EgressDeparser(packet_out packet,
                  inout headers hdr,
                  in egress_metadata md,
                  in egress_intrinsic_metadata_for_deparser_t eg_dps_md) {
            
    apply { 
        packet.emit(hdr);
    }
}

Pipeline(IngressParser(), Ingress(), IngressDeparser(), EgressParser(), Egress(), EgressDeparser()) pipe;

Switch(pipe) main;
