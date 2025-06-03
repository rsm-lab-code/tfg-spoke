terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
      configuration_aliases = [
        aws.delegated_account_us-west-2
      ]
    }
  }
}
