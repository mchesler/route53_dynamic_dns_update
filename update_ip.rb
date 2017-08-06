#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'ostruct'

class UpdateDNS
  attr_reader :options

  def initialize(args)
    @options = OpenStruct.new
    parse(args)
  end

  def parse(args)
    opts = OptionParser.new do |opts|
      opts.on('-h', '--hostname HOSTNAME', 'Hostname to update') do |hostname|
        options.hostname = hostname
      end

      opts.on('-z', '--zone-id ZONE_ID', 'AWS Route53 Zone ID to update') do |zone_id|
        options.zone_id = zone_id
      end

      opts.on('-?', '--help', 'Display this message') do
        puts opts
        exit
      end
    end

    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

    begin
      opts.parse!(args)
      raise OptionParser::MissingArgument.new("Must provide zone ID") unless options.zone_id
      raise OptionParser::MissingArgument.new("Must provide hostname") unless options.hostname
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts opts
      exit(1)
    end
  end

  def route53
    @route53 ||= Aws::Route53::Client.new(region: 'us-east-1')
  end

  def observed_ip
    @observed_ip ||= `/usr/bin/dig +short myip.opendns.com @resolver1.opendns.com`.chomp
  end

  def route53_ip
    @route53_ip ||= begin
      route53.list_resource_record_sets({
        hosted_zone_id: options.zone_id,
        start_record_name: options.hostname,
        start_record_type: 'A',
        max_items: 1
      })
        .resource_record_sets.first
        .resource_records.first
        .value
    rescue Aws::Route53::Errors::ServiceError, Aws::Errors::MissingCredentialsError => e
      raise e
    rescue => e
      puts e.inspect
      nil
    end
  end

  def update_ip
    puts "[#{Time.now}] Updating #{options.hostname} from #{route53_ip} to #{observed_ip}"
    begin
      route53.change_resource_record_sets({
        change_batch: {
          changes: [{
            action: 'UPSERT',
            resource_record_set: {
              name: options.hostname,
              resource_records: [{
                value: observed_ip
              }],
              ttl: 60,
              type: 'A'
            }
          }]
        },
        hosted_zone_id: options.zone_id
      })
    rescue Aws::Route53::Errors::ServiceError => e
      puts "Failed to update IP: #{e.message}"
    end
  end

  def go!
    if observed_ip == route53_ip
      puts "[#{Time.now}] Nothing to update, #{observed_ip} is current"
    else
      update_ip
    end
  end
end

UpdateDNS.new(ARGV).go!

