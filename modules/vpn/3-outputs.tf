output "aws_tunnel1_outside_ip" {
  description = "AWS VPN Tunnel 1 outside/public IP"
  value       = aws_vpn_connection.tgw_aws_to_gcp.tunnel1_address
}

output "aws_tunnel2_outside_ip" {
  description = "AWS VPN Tunnel 2 outside/public IP"
  value       = aws_vpn_connection.tgw_aws_to_gcp.tunnel2_address
}

output "aws_tunnel1_inside_cidr" {
  description = "AWS VPN Tunnel 1 inside CIDR (link-local)"
  value       = aws_vpn_connection.tgw_aws_to_gcp.tunnel1_inside_cidr
}

output "aws_tunnel2_inside_cidr" {
  description = "AWS VPN Tunnel 2 inside CIDR (link-local)"
  value       = aws_vpn_connection.tgw_aws_to_gcp.tunnel2_inside_cidr
}