# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "stage" {
  description = "Deployment stage"
  type        = string
}
