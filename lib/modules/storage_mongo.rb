require 'mongoid'
require 'json'
require 'bson'
require 'moped'

# MongoID class for storing permissions
class Permission
  include Mongoid::Document
  #field :_id, pre_processed: true, default: ->{Moped::BSON::ObjectId}
  field :username, :type => String
  field :enabled, :type => Boolean
  field :is_admin, :type => Boolean
  field :tags, :type => Array
end

# MongoID class for storing favorites
class Favorite
  include Mongoid::Document
  field :_id, :type => String, pre_processed: true, default: ->{(0...10).map{65.+(rand(26)).chr}.join}
  field :name, :type => String
  field :user, :type => String 
  field :searchstring, :type => String
  field :hashcode, :type => String
end

class StorageMongo
  # Required function, accepts a KibanaConfig object
  def initialize(config)
    @config = config
    @mongo_host = (defined? config::Mongo_host) ? config::Mongo_host : ''
    @mongo_port = (defined? config::Mongo_port) ? config::Mongo_port : 27017
    @mongo_db = (defined? config::Mongo_db) ? config::Mongo_db : ''
    @mongo_usr = (defined? config::Mongo_usr) ? config::Mongo_usr : ''
    @mongo_pw = (defined? config::Mongo_pw) ? config::Mongo_pw : '
    puts "Initializing mongo (#{@mongo_host}:#{@mongo_port}/#{@mongo_db}) for kibana storage..."
    Mongoid.configure do |iconfig|
      iconfig.sessions = {default:{database: @mongo_db, hosts: [@mongo_host+':'+@mongo_port.to_s], username: @mongo_usr, password: @mongo_pw}}
      #iconfig.options = {include_type_for_serialization: false, protect_sensitive_fields: false}
    end
  end

  # Helper function
  def lookup_permissions(username)
    p = Permission.where(:username => username)[0].as_json
    return p
  end

  def get_permissions(username)
    return Permission.where(:username => username)[0]
  end

  def get_all_permissions()
    return Permission.all().to_a
  end

  def get_all_users()
    begin
	p = get_all_permissions()
	result = Array.new
	p.each do |item|
	  result.push(item[:username])
	end
	return result.sort
    rescue => details
	p "#{details.backtrace.join("\n")}"
	return []
    end
  end
		
  # Required function, sets the user's permissions
  def set_permissions(username,tags = [],is_admin = false)
    begin
      p = get_permissions(username)
      if !p
        # upsert
        p = Permission.create!
        p[:username] = username
      end
      #tags includes the name of groups it belongs to, which start with '@'
      unless (tags.include? "@default")||(username.start_with?("@"))
	tags.push("@default")
      end
      p[:tags] = tags
      p[:is_admin] = is_admin
      p[:enabled] = true
      #p "new record: #{p}"
      p.save!
      if !p.persisted?
        raise "Failed to save user data for #{username}"
      end
      return p
    rescue => details
      p "#{details.backtrace.join("\n")}"
      # TODO: log message?
      return false
    end
  end

  # Required function, enables a user
  def enable_user(username)
    begin
      p = lookup_permissions(username)
      if !p
        raise "Username not found"
      end
      p[:enabled] = true
      p.save!
      if !p.persisted?
        raise "Failed to save user data for #{username}"
      end
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end

  # Required function, disables a user
  def disable_user(username)
    begin
      p = lookup_permissions(username)
      if !p
        raise "Username not found"
      end
      p[:enabled] = false
      p.save!
      if !p.persisted?
        raise "Failed to save user data for #{username}"
      end
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end

  #delete permission
  def del_permissions(username)
    begin
      p = get_permissions(username)
      if p
        p.delete
        return true
      end
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end


  # Sets a favorite
  def set_favorite(name,user,searchstring,hashcode)
    begin
      p = Favorite.where(:name => name)[0]
      if !p
        p = Favorite.create!
        #id = (0...10).map{65.+(rand(26)).chr}.join
        #p._id = id
        p[:name] = name
        p[:user] = user
        p[:searchstring] = searchstring
	p[:hashcode] = hashcode
        p.save!
      else
        p "Duplicate name"
        return false
      end
      if !p.persisted?
        raise "Failed to save favorite data for #{name}"
      end
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      # TODO: log message?
      return false
    end
  end

  # Deletes a favorite
  def del_favorite(id)
    begin
      p = Favorite.where(:_id => id)
      if p
        p.delete
        return true
      end
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end

  # Get the user's favorites
  def get_favorites(user)
    begin
      response = Favorite.where(:user => user)
      if response
        result = Array.new
        response.each_with_index do |item, index|
                result.push(response[index].as_json)
        end
        return result
      end
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return nil
    end
  end

  # Get a favorite
  def get_favorite(id)
    begin
      p = Favorite.where(:_id => id).as_json[0]
      if p
        return p
      end
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return nil
    end
  end
end

# Required function, returns the storage
# class for this module.
def get_storage_module(config)
  return StorageMongo.new(config)
end
