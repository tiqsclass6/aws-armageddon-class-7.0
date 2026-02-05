# Liberdade Transit Gateway
resource "aws_ec2_transit_gateway" "liberdade_tgw" {
  provider                        = aws.liberdade
  description                     = "Liberdade TGW"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-tgw"
  })
}

# Transit Gateway Route Table in Liberdade Region
resource "aws_ec2_transit_gateway_route_table" "liberdade_tgw_rt" {
  provider           = aws.liberdade
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-tgw-rt"
  })
}

# VPC Attachment to Liberdade VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_vpc_attachment" {
  provider           = aws.liberdade
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id
  vpc_id             = aws_vpc.liberdade.id
  subnet_ids         = [aws_subnet.liberdade_private[0].id, aws_subnet.liberdade_private[1].id]

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-tgw-vpc-attach"
  })
}

# Peering Attachment Accepter (Shinjuku -> Liberdade)
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer" {
  provider                      = aws.liberdade
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer.id

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-tgw-peer-accepter"
  })
}

# Associations
resource "aws_ec2_transit_gateway_route_table_association" "liberdade_assoc_vpc" {
  provider                       = aws.liberdade
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "liberdade_assoc_peer" {
  provider                       = aws.liberdade
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt.id
}

# Route (Liberdade -> Shinjuku)
resource "aws_ec2_transit_gateway_route" "liberdade_to_shinjuku" {
  provider                       = aws.liberdade
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt.id
  destination_cidr_block         = local.shinjuku_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer.transit_gateway_attachment_id
}

# Route (Liberdade -> Liberdade VPC)
resource "aws_ec2_transit_gateway_route" "liberdade_to_liberdade_vpc" {
  provider                       = aws.liberdade
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt.id
  destination_cidr_block         = local.liberdade_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_vpc_attachment.id
}

# Route in Liberdade Private Route Table to Shinjuku VPC via TGW
resource "aws_route" "liberdade_private_to_shinjuku" {
  provider               = aws.liberdade
  route_table_id         = aws_route_table.liberdade_private.id
  destination_cidr_block = local.shinjuku_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.liberdade_vpc_attachment,
    aws_ec2_transit_gateway_route_table_association.liberdade_assoc_peer,
  ]
}