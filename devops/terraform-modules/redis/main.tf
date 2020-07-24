provider "aws" {
  version = "~> 2.23"

  profile = "${var.profile}"
  region = "${var.region}"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region = "${var.region}"
    bucket = "${var.tfstate_bucket}"
    key = "vpc/terraform.tfstate"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "lamp"
  subnet_ids = ["${data.terraform_remote_state.vpc.private_subnet_ids}"]
}

resource "aws_security_group" "redis" {
  name = "webserver -: redis"
  description = "Allow connections from webservers"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.public_subnets_cidr_blocks}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}: Redis"
    Environment = "${var.environment}"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "prod-cluster"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  subnet_group_name = "${aws_elasticache_subnet_group.redis.name}"
  security_group_ids = ["${aws_security_group.redis.id}"]
  availability_zone = "us-east-1a"

}
