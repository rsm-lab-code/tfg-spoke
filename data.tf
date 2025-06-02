data "aws_availability_zones" "available" {
  provider = aws.delegated_account_us-west-2
  state    = "available"
  filter {
    name   = "region-name"
    values = [var.aws_regions[0]]
  }
}
