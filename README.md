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
     ![Keep it secret - keep it safe.](aws-secrets.gif)
 - Register a domain with [Route53](https://console.aws.amazon.com/route53)
   - Be sure to make note of the "Hosted Zone ID" once the domain is created - you'll need it later.
 - Create an [S3 bucket](https://s3.console.aws.amazon.com/s3) with an easy-to-remember label. This will be where your TFState files are kept. Ensure that 'Block all public access' is checked, then, after creation of the bucket, go to the 'Permissions' tab and then 'Access Control List.' 'Access for Bucket Owner' should have 'Yes' listed across all four permissions groups.
 - _Optional_: Create an additional [S3 bucket](https://s3.console.aws.amazon.com/s3) that will contain your publicly-served files. You will want to *uncheck* 'Block _all_ public access.'
 - Create a keypair with the name `github_deploy_key` and add it as a deploy key to your Github repo. *IMPORTANT*: Currently, this key is checked in to the devops repo. It is therefore _imperative_ that you *not* check 'Allow write access' on the Github Add Key form. Store the keypair in `/devops/files`.


Initial configuration
---------------------
The first step

## License
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
