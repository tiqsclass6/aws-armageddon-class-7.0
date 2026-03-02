output "aws_tgw_id" {
  description = "AWS Transit Gateway ID"
  value       = module.aws_tokyo.tgw_id
}

output "aws_tunnel1_outside_ip" {
  description = "AWS VPN Tunnel 1 Outside IP"
  value       = module.vpn.aws_tunnel1_outside_ip
}

output "aws_tunnel2_outside_ip" {
  description = "AWS VPN Tunnel 2 Outside IP"
  value       = module.vpn.aws_tunnel2_outside_ip
}

output "gcp_ilb_ip" {
  description = "GCP Internal Load Balancer IP"
  value       = module.gcp_iowa.ilb_ip
}