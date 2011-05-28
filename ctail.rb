#!/usr/bin/env ruby

require 'open-uri'
require 'net/http'
require 'net/https'
require 'optparse'
require 'json'

CONVORE_URL = "https://convore.com"

GROUPS_URL = "#{CONVORE_URL}/api/groups.json"
TOPICS_URL = "#{CONVORE_URL}/api/groups/%s/topics.json"
TOPIC_URL = "#{CONVORE_URL}/api/topics/%s/messages.json"

config_file = "#{ENV['HOME']}/.convore"
unless File.exist?(config_file)
  puts "You need to type your username and password (one per line) into #{config_file}."
  exit!(1)
end

user,password = File.read(config_file).split("\n")

# Get groups we know about
url = URI.parse(GROUPS_URL)
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
req = Net::HTTP::Get.new(url.path)
req.basic_auth(user, password)
res = http.start{|h| h.request(req) }

groups = {}

JSON.parse(res.body)["groups"].each {|group| groups[group["id"]] = {:name => group["name"] }}

groups.each_pair {|id, group|
   topics = {}
   url = URI.parse(TOPICS_URL % id)
   http = Net::HTTP.new(url.host, url.port)
   http.use_ssl = true
   req = Net::HTTP::Get.new(url.path)
   req.basic_auth(user, password)
   res = http.start{|h| h.request(req) }
   JSON.parse(res.body)["topics"].each {|topic| 
      topics[topic["id"]] = { 
         :name => topic["name"],
         :url => topic["url"]
      }
   }

   group[:topics] = topics
}

groups.each do |id, group|
   group[:topics].each_pair do |id, topic|
      url = URI.parse(TOPIC_URL % id)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(url.path)
      req.basic_auth(user, password)
      #req.set_form_data({ :mark_read => false })
      res = http.start{|h| h.request(req) }
      json = JSON.parse(res.body)
      data = json["messages"]

      puts "\n #{group[:name]} -- #{topic[:name]} \n"
      data.each {|msg|
         username = msg["user"]["username"]
         time = Time.at msg["date_created"]
         timestr = time.strftime "<%m/%d/%Y %H:%M:%S>"

         puts "\t#{timestr} #{user}: #{msg["message"]}" if !msg.nil?
      }
   end
end
