Nigh-instantaneous CI/CD
=========

This project utilizes [Terraform](https://github.com/hashicorp/terraform), [Terragrunt](https://github.com/gruntwork-io/terragrunt), [AWS](https://aws.amazon.com), and a PHP-based CMS of your choice - for this specific example, we are using [Drupal](https://drupal.org).

Getting Started & Documentation
-------------------------------
Documentation is available on each of the aforementioned repositories or websites.

Prerequisites
-------------
 - Create a console account with [AWS](https://console.aws.amazon.com)
   - Your account will be provisioned with an AWS access key and secret.
   - Create an [EC2 Keypair](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:) as well.
     ![Keep it secret - keep it safe.](aws-secrets.gif)
 - Register a domain with [Route53](https://console.aws.amazon.com/route53)
   - Be sure to make note of the "Hosted Zone ID" once the domain is created - you'll need to add it as the zone_id in `terraform-modules/webserver/main.tf`, under the `resource "aws_route53_record" "validation"` resource.
 - Create an [S3 bucket](https://s3.console.aws.amazon.com/s3) with an easy-to-remember label. This will be where your TFState files are kept. Ensure that 'Block all public access' is checked, then, after creation of the bucket, go to the 'Permissions' tab and then 'Access Control List.' 'Access for Bucket Owner' should have 'Yes' listed across all four permissions groups.
 - _Optional_: Create an additional [S3 bucket](https://s3.console.aws.amazon.com/s3) that will contain your publicly-served files. You will want to *uncheck* 'Block _all_ public access.'
 - Create a keypair with the name `github_deploy_key` and add it as a deploy key to your Github repo. *IMPORTANT*: Currently, this key is checked in to the devops repo. It is therefore _imperative_ that you *not* check 'Allow write access' on the Github Add Key form. Store the keypair in `/devops/files`.
 - Modify the Directory directives starting at around line 129 of `files/httpd.conf` to match your particular requirements.
 - Modify `files/php-7.2.ini` if necessary (probably not necessary though).
 - Modify the `git clone` portion of `packer.json` to match your repo.

Initial configuration
---------------------
 - Modify terraform.tfvars `bucket` config definition to match the S# bucket you created earlier.
 - Modify webserver terraform.tfvars to match your setup.

## License
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Non-Github version
------------------
If you don't want to use Github or Github actions for this config, ensure that you have the following:
* AWS Account (there is [free tier](https://aws.amazon.com/free/) if you don't have an account yet)
* aws-cli (latest)
* Packer (latest)
* Terraform v0.11.14 (other versions may work too)
* librarian-chef 0.0.4

First, create the webserver image:
```
packer build \
        -var "aws_access_key=MAHPUBLICKKEY" \
        -var "aws_secret_key=MAHSEEKRITKEY" \
        -var "region=us-east-1" \
        -var "build_version=1" \
        packer.json
```

Next, run Terragrunt and get everything deployed:
```
cd <environment>/
terragrunt init
AWS_PROFILE=myaccount terragrunt apply-all
```

@To-Dos
-------
 - Move domain-related configuration into environment-specific tfvars files.
 - Properly handle permissions for the deploy key.
