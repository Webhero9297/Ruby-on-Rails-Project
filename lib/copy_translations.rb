require 'mongo'
include Mongo

puts Mongo


@client = MongoClient.new('intervac-staging.modondo.com', 27017)
@db     = @client['intervac_production']
@coll   = @db['translations']

@local_client = MongoClient.new('localhost', 27017)
@local_db     = @local_client['intervac_staging']
@local_coll   = @local_db['translations']





puts "There are #{@coll.count} records. Here they are:"
@coll.find({:locale => "is_IS", :value => nil}).each { |doc| 
        puts doc["msgid"]
        local_doc = @local_coll.find_one("_id" => doc["_id"])
        if local_doc
          puts local_doc["value"]
          @coll.update({"_id" => doc["_id"]}, {"$set" => {"value" => local_doc["value"]}})
        end
        puts "------------------------------"
}

