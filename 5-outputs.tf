output "aws_tgw_id" {
  value = module.aws_tokyo.tgw_id
}

output "gcp_ilb_ip" {
  value = module.gcp_iowa.ilb_ip
}

output "aws_tunnel1_outside_ip" {
  value = module.vpn.aws_tunnel1_outside_ip
}

output "aws_tunnel2_outside_ip" {
  value = module.vpn.aws_tunnel2_outside_ip
}