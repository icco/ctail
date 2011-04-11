#!/usr/bin/env ruby

require 'open-uri'
require 'net/http'
require 'net/https'
require 'optparse'
require 'json'

CONVORE_URL = "https://convore.com"

user = "icco"
password = "nat100"

GROUPS_URL = "#{CONVORE_URL}/api/groups.json"
TOPICS_URL = "#{CONVORE_URL}/api/groups/%s/topics.json"
TOPIC_URL = "#{CONVORE_URL}/api/topics/%s/messages.json"

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
      req.set_form_data({ :mark_read => false })
      res = http.start{|h| h.request(req) }
      json = JSON.parse(res.body)

      puts "\nGroup: #{group[:name]}"
      puts "\t #{topic[:name]}"
      json.each {|msg|
         puts "\t\t#{msg[:user][:username]}: #{msg[:message]}" if !msg.nil?
      }
   end
end
