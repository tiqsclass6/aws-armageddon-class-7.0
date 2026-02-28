variable "name_prefix" {
  type = string
}

variable "aws_tgw_id" {
  type = string
}

variable "aws_tgw_route_table_id" {
  type = string
}

variable "gcp_ha_vpn_interface0_ip" {
  description = "Public IP of GCP HA VPN gateway interface 0"
  type        = string
}

variable "gcp_ha_vpn_interface1_ip" {
  description = "Public IP of GCP HA VPN gateway interface 1"
  type        = string
}

variable "aws_bgp_asn" {
  type = number
}

variable "gcp_bgp_asn" {
  type = number
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