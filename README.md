# route53_dynamic_dns_update
A simple script to update an A record at Route53 with your current IP.

I run this periodically from cron on a machine at home to update a record in a Route53 hosted zone with the current IP.
This allows me to always refer to home by a name, and not have to worry about when my ISP changes my IP.

## Installation

Bundler - `bundle install`

## Config

The script requires that you have AWS credentials set, either via environment variables, or `.aws/credentials`.
See http://docs.aws.amazon.com/sdkforruby/api/index.html#Configuration for more info

## Usage

```
Usage: update_ip.rb [options]
    -h, --hostname HOSTNAME          Hostname to update
    -z, --zone-id ZONE_ID            AWS Route53 Zone ID to update
    -?, --help                       Display this message
```

## Run via cron

My crontab for this script looks like:
```
AWS_ACCESS_KEY_ID="ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="SECRET_ACCESS_KEY"
* * * * * cd /path/to/route53_dynamic_dns_update && bundle exec ./update_ip.rb -h hostname.domain.tld -z hosted_zone_id >> /path/to/log/file.log 2>&1
```
