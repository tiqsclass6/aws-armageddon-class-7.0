variable "aws_bgp_asn" {
  description = "ASN to use for the AWS side of the BGP session"
  type        = number
}

variable "aws_tgw_id" {
  description = "ID of the AWS Transit Gateway to use for the VPN attachment"
  type        = string
}

variable "aws_tgw_route_table_id" {
  description = "ID of the AWS Transit Gateway route table to use for the VPN attachment"
  type        = string
}

variable "bgp_link_local" {
  description = "Lab-mandated link-local ranges and peer IPs (TWO tunnels only)"
  type = object({
    aws_tunnel1_inside_cidr = string
    aws_tunnel2_inside_cidr = string
    gcp_iface1_range        = string
    gcp_iface2_range        = string
    gcp_peer1_ip            = string
    gcp_peer2_ip            = string
  })
}

variable "gcp_ha_vpn_interface0_ip" {
  description = "Public IP of GCP HA VPN gateway interface 0"
  type        = string
}

variable "gcp_ha_vpn_interface1_ip" {
  description = "Public IP of GCP HA VPN gateway interface 1"
  type        = string
}

variable "gcp_bgp_asn" {
  description = "ASN to use for the GCP side of the BGP session"
  type        = number
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "tunnel1_psk" {
  description = "Tunnel 1 PSK (out-of-band)"
  type        = string
  sensitive   = true
}

variable "tunnel2_psk" {
  description = "Tunnel 2 PSK (out-of-band)"
  type        = string
  sensitive   = true
}