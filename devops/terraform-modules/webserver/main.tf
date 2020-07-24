data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region = "${var.region}"
    bucket = "${var.tfstate_bucket}"
    key = "vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config {
    region = "${var.region}"
    bucket = "${var.tfstate_bucket}"
    key = "database/terraform.tfstate"
  }
}

data "terraform_remote_state" "redis" {
  backend = "s3"

  config {
    region = "${var.region}"
    bucket = "${var.tfstate_bucket}"
    key = "redis/terraform.tfstate"
  }
}

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.23"

  # default location is $HOME/.aws/credentials
  profile = "${var.profile}"
  region = "${var.region}"
}

data "template_cloudinit_config" "readmodel" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/part-handler"
    content = "${file("${path.module}/../part-handler-text.py")}"
  }

  part {
    content_type = "text/plain-base64"
    filename = "/etc/environment"
    content = "${base64encode("DB_HOST=${data.terraform_remote_state.database.server_address}
DB_DATABASE=rhgithubdb
DB_USERNAME=root
DB_PASSWORD=TerriblePassword
APP_URL=https://prod.philsgitemporium.com
REDIS_HOST=${data.terraform_remote_state.redis.redis_server_address}")}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/scripts/s3fsmount.sh")}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/scripts/mysql-create.sh")}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/scripts/restart-httpd.sh")}"
  }
}

resource "aws_autoscaling_group" "webserver" {
  lifecycle { create_before_destroy = true }
  name = "${aws_launch_configuration.webserver.name}"
  launch_configuration = "${aws_launch_configuration.webserver.name}"

  max_size = "${4 * length(data.terraform_remote_state.vpc.public_subnet_ids)}"
  min_size = 1

  vpc_zone_identifier = ["${data.terraform_remote_state.vpc.public_subnet_ids}"]
  load_balancers = ["${aws_elb.webserver.name}"]

  tag {
    key = "Name"
    value = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key = "Environment"
    value = "${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      "Name" = "${var.name}",
      "Environment" = "${var.environment}"
  }
}

resource "aws_iam_instance_profile" "s3_access_role" {
  name = "s3_access_role"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_launch_configuration" "webserver" {
  name_prefix = "webserver-"
  image_id = "${data.aws_ami.webserver.id}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.s3_access_role.name}"
  key_name = "prodrhgithubprez"
  user_data = "${data.template_cloudinit_config.readmodel.rendered}"

  security_groups = [
    "${aws_security_group.webserver.id}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "default" {
  domain_name       = "prod.philsgitemporium.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "validation" {
  depends_on = ["aws_acm_certificate.default"]

  name    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  zone_id = "Z0483476T1VPBH3G04IH"
  records = ["${aws_acm_certificate.default.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}

resource "aws_elb" "webserver" {
  name = "webserver-elb"
  internal = false
  subnets = ["${data.terraform_remote_state.vpc.public_subnet_ids}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port = 80
    instance_protocol = "tcp"
    lb_port = 80
    lb_protocol = "tcp"
  }

  listener {
    instance_port = 443
    instance_protocol = "https"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${aws_acm_certificate_validation.default.certificate_arn}"
  }

  listener {
    instance_port = 5000
    instance_protocol = "tcp"
    lb_port = 5000
    lb_protocol = "tcp"
  }


  tags {
    Name = "${var.environment}: ${var.name}"
  }
}

resource "aws_lb_cookie_stickiness_policy" "stickiness_policy_ssl" {
  name                     = "venkit-prod-stickiness-policy-ssl"
  load_balancer            = "${aws_elb.webserver.id}"
  lb_port                  = 443
  cookie_expiration_period = 21600
}


resource "aws_route53_record" "placeholderwww" {
  zone_id = "Z0483476T1VPBH3G04IH"
  name    = "philsgitemporium.com"
  type    = "A"

  alias {
    name                   = "${aws_elb.webserver.dns_name}"
    zone_id                = "${aws_elb.webserver.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "r53webserver" {
  zone_id = "Z0483476T1VPBH3G04IH"
  name    = "prod.philsgitemporium.com"
  type    = "A"

  alias {
    name                   = "${aws_elb.webserver.dns_name}"
    zone_id                = "${aws_elb.webserver.zone_id}"
    evaluate_target_health = true
  }
}


data "aws_ami" "webserver" {
  most_recent = true
  owners = ["${data.aws_caller_identity.current.account_id}"]

  filter {
    name = "name"
    values = ["webserver-*"]
  }

  filter {
    name = "state"
    values = ["available"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "is-public"
    values = ["false"]
  }
}

data "aws_caller_identity" "current" {
  # no arguments
}

resource "aws_security_group" "webserver" {
  name = "elb -: webserver"
  description = "Allow connections from ELB"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.public_subnets_cidr_blocks}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.public_subnets_cidr_blocks}"]
  }


  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["199.255.11.3/32", "204.16.137.178/32", "24.199.203.50/32", "99.149.121.138/32", "149.168.132.14/32", "104.186.149.153/32", "66.61.222.218/32", "40.136.78.10/32"]
  }

  ingress {
    from_port = 5000
    to_port = 5000
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
    Name = "${var.name}: webserver"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "elb" {
  name = "Internet -: ELB"
  description = "Allow connections from Internet"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}: ELB"
    Environment = "${var.environment}"
  }
}
