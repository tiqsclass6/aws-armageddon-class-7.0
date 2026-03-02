locals {
  # Lab 4 non-negotiable link-local ranges:
  bgp_link_local = {
    aws_tunnel1_inside_cidr = "169.254.12.0/30"
    aws_tunnel2_inside_cidr = "169.254.12.4/30"
    gcp_iface1_range        = "169.254.12.2/30"
    gcp_iface2_range        = "169.254.12.6/30"
    gcp_peer1_ip            = "169.254.12.1"
    gcp_peer2_ip            = "169.254.12.5"
  }
}

# Tunnel 1 uses 169.254.12.0/30
# Tunnel 2 uses 169.254.12.4/30