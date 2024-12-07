# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }


    tls = {
      source = "hashicorp/tls"
    }

    cloudinit = {
      source = "hashicorp/cloudinit"
    }
  }

  required_version = "~> 1.3"
}

