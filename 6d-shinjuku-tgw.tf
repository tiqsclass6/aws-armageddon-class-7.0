# Transit Gateway in Shinjuku Region
resource "aws_ec2_transit_gateway" "shinjuku_tgw" {
  provider                        = aws.shinjuku
  description                     = "Shinjuku TGW"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-tgw"
  })
}

# Transit Gateway Route Table in Shinjuku Region
resource "aws_ec2_transit_gateway_route_table" "shinjuku_tgw_rt" {
  provider           = aws.shinjuku
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw.id

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-tgw-rt"
  })
}

# VPC Attachment to Shinjuku VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_vpc_attachment" {
  provider           = aws.shinjuku
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw.id
  vpc_id             = aws_vpc.shinjuku.id
  subnet_ids         = [aws_subnet.shinjuku_private[0].id, aws_subnet.shinjuku_private[1].id]

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-tgw-vpc-attach"
  })
}

# Peering Attachment (Shinjuku -> Liberdade)
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer" {
  provider                = aws.shinjuku
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id
  peer_region             = "sa-east-1"

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-to-liberdade-peer"
  })
}

# Associations
resource "aws_ec2_transit_gateway_route_table_association" "shinjuku_assoc_vpc" {
  provider                       = aws.shinjuku
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shinjuku_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "shinjuku_assoc_peer" {
  provider                       = aws.shinjuku
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer
  ]
}

# Route (Shinjuku -> Liberdade)
resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade" {
  provider                       = aws.shinjuku
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt.id
  destination_cidr_block         = local.liberdade_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer
  ]
}

# Route (Shinjuku -> Shinjuku VPC)
resource "aws_ec2_transit_gateway_route" "shinjuku_to_shinjuku_vpc" {
  provider                       = aws.shinjuku
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt.id
  destination_cidr_block         = local.shinjuku_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shinjuku_vpc_attachment.id
}

# Route in Shinjuku Private Route Table to Liberdade VPC via TGW
resource "aws_route" "shinjuku_private_to_liberdade" {
  provider               = aws.shinjuku
  route_table_id         = aws_route_table.shinjuku_private.id
  destination_cidr_block = local.liberdade_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.shinjuku_vpc_attachment,
    aws_ec2_transit_gateway_route_table_association.shinjuku_assoc_peer,
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer,
  ]
}