output "network_id" {
  description = "Network ID"
  value       = google_compute_network.nihonmachi_vpc.id
}

output "router_name" {
  description = "Router Name"
  value       = google_compute_router.nihonmachi_router.name
}

output "ha_vpn_gateway_id" {
  description = "HA VPN Gateway ID"
  value       = google_compute_ha_vpn_gateway.nihonmachi_ha_vpn.id
}

output "ha_vpn_interface0_ip" {
  description = "HA VPN interface 0 external IP (use as AWS Customer Gateway IP)"
  value       = google_compute_ha_vpn_gateway.nihonmachi_ha_vpn.vpn_interfaces[0].ip_address
}

output "ha_vpn_interface1_ip" {
  description = "HA VPN interface 1 external IP"
  value       = google_compute_ha_vpn_gateway.nihonmachi_ha_vpn.vpn_interfaces[1].ip_address
}

# --- Deliverable outputs ---
output "ilb_ip" {
  description = "Internal LB IP for nihonmachi-fr (private-only over VPN corridor)"
  value       = google_compute_forwarding_rule.nihonmachi_fr.ip_address
}

output "mig_name" {
  description = "Managed Instance Group name"
  value       = google_compute_region_instance_group_manager.nihonmachi_mig.name
}


output "ncc_hub_id" {
  description = "Network Connectivity Center hub ID"
  value       = google_network_connectivity_hub.nihonmachi_hub.id
}

output "ncc_hub_name" {
  description = "NCC hub name"
  value       = google_network_connectivity_hub.nihonmachi_hub.name
}