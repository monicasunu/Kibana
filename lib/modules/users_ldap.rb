require 'net/ldap'
require './lib/modules/storage_mongo.rb'

class UsersLDAP
  # Required function, accepts a KibanaConfig object
  def initialize(config)
    @ldap = Net::LDAP.new
    @ldap.host = (defined? config::Ldap_host) ? config::Ldap_host : "dc05-sc.corp.shutterfly.com"
    @ldap.port = (defined? config::Ldap_port) ? config::Ldap_port : 636
    @ldap_user_base = (defined? config::Ldap_user_base) ? config::Ldap_user_base : "CN=svc-giza,OU=Accounts-Service,OU=Controlled Objects,OU=shutterfly,DC=corp,DC=shutterfly,DC=com"
    @ldap_group_base = (defined? config::Ldap_group_base) ? config::Ldap_group_base : "DC=corp,DC=shutterfly,DC=com"
    #@ldap_suffix = (defined? config::Ldap_domain_fqdn) ? "@" + config::Ldap_domain_fqdn : ""
    @ldap.encryption(:simple_tls)
    @storage = get_storage_module(config)
  end

  # Required function, returns user's groups membership
  def membership(username)
    begin
      if username.start_with?("@")
	raise "user #{username} is not a user"
      end
      grlist = []
      unless p = @storage.get_permissions(username)
        raise "user #{username} does not exists"
      end
      orglist = p[:tags]
      if orglist.include? '*'
	grlist = groups()
      else
	orglist.each do |item| 
          if item.start_with?("@")
            grlist.push(item[1..-1])
	  else
	    raise "membership #{item} is not a group"
          end
	end
      end 
      return grlist.uniq.sort
    rescue => details
      p "#{details.backtrace.join("\n")}"
      # TODO: log message?
      return nil
    end
  end

  # Required function, returns a list of all groups
  def groups()
    grlist = []
    orglist = @storage.get_all_users()
    orglist.each do |item|
	if item.start_with?("@")
	  grlist.push(item[1..-1])
	end
    end
    return grlist.uniq.sort
  end

  def users()
    usrlist = []
    orglist = @storage.get_all_users()
    orglist.each do |item|
        unless item.start_with?("@")
          usrlist.push(item)
        end
    end
    return usrlist.uniq.sort 
  end

  def del_user(name)
    begin
      if name.start_with?("@")
	raise "name #{name} is a group"
      end
      grlist = @storage.get_all_permissions()
      grlist.each do |item|
        if (item[:username].start_with?("@")) && (item[:tags].include? name)
          newtags = item[:tags]
	  newtags.delete(name)
          @storage.set_permissions(item[:username], newtags.uniq, item[:is_admin])
        end
      end
      @storage.del_permissions(name)
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end

  def del_group(name)
    begin
      unless name.start_with?("@")
	raise "name #{name} is a user name"
      end
      userlist = @storage.get_all_permissions()
      userlist.each do |item|
      	unless (item[:username].start_with?("@")) || !(item[:tags].include? name)
	  newtags = item[:tags]
	  newtags.delete(name)
	  @storage.set_permissions(item[:username], newtags.uniq, item[:is_admin])
        end
      end
      @storage.del_permissions(name)
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      return false
    end
  end
 
  def group_members(name)
    begin
      #grname = '@'+name
      usrlist = []
      unless p=@storage.get_permissions(name)
	raise "group #{name} does not exists"
      end
      orglist = p[:tags]
      if orglist.include? '*'
        usrlist = users()
      else
    	usrlist = orglist
      end
      return usrlist.uniq.sort
    rescue => details
      p "#{details.backtrace.join("\n")}"
      # TODO: log message?
      return nil
    end
  end

# users' tags with '*' will automatically added
  def add_group(name, tags=[], is_admin = false)
    begin
      unless name.start_with?("@")
        raise "name #{name} is not a group name"
      end
      usrlist = @storage.get_all_permissions()
      usrlist.each do |item|
	unless item[:username].start_with?('@')
          if ((!tags.include? '*') &&
	     (!tags.include? item[:username]) && 
	     ((item[:tags].include? name) || (item[:tags].include? '*')))
 	    tags.push(item[:username])
          end 
          if ((!item[:tags].include? "*") &&
	     (!item[:tags].include? name) && 
	     (tags.include? item[:username] || (tags.include? '*')))
	    newtags = item[:tags]
	    newtags.push(name)
	    @storage.set_permissions(item, newtags.uniq, usrperm[:is_admin])
          end
	end
      end
      @storage.set_permissions(name,tags.uniq,is_admin)
      return true
    rescue => details
      p "#{details.backtrace.join("\n")}"
      # TODO: log message?
      return false
    end
  end

  #no change for tags '*'
  def add_user_2group(username, groupname)
    begin
    	#grname = '@'+ groupname
      p = @storage.get_permissions(groupname)
      unless p && (groupname.start_with?('@'))
	raise "group #{groupname} does not exists"
      end
      usrlist = p[:tags]
      q=@storage.get_permissions(username)
      unless q && (!username.start_with?('@'))
        raise "user #{username} does not exists"
      end
      grlist = q[:tags]
      unless (usrlist.include? '*') || (usrlist.include? username)
        usrlist.push(username)
	@storage.set_permissions(groupname, usrlist.uniq, p[:is_admin])
      end
      unless (grlist.include? '*') || (grlist.include? groupname)
        grlist.push(groupname)
        @storage.set_permissions(username, grlist.uniq, q[:is_admin])
      end
      return true
    rescue => details
	p "#{details.backtrace.join("\n")}"
	# TODO: log message?
	return false
    end
  end

  def rm_user_from_group(username, groupname)
    begin
        #grname = '@'+ groupname
	p = @storage.get_permissions(groupname)
        unless p && (groupname.start_with?('@'))
	  raise "group #{groupname} does not exist"
        end
        usrlist = p[:tags]
	q=@storage.get_permissions(username)
        unless q && (!username.start_with?('@'))
          raise "user #{username} does not exist"
        end
        grlist = q[:tags]
	if grlist.include? groupname
	  grlist.delete(groupname)
	elsif grlist.include? '*'
	  grlist = groups().delete(groupname)
	end 
	@storage.set_permissions(username, grlist.uniq, q[:is_admin])
	if usrlist.include? username
	  usrlist.delete(username)
	elsif usrlist.include? '*'
	  usrlist = users().delete(username)
	end
	@storage.set_permissions(groupname, usrlist.uniq, p[:is_admin])
        return true
    rescue => details
        p "#{details.backtrace.join("\n")}"
        # TODO: log message?
        return false
    end
  end
end

# Required function, returns the auth
# class for this module.
def get_users_module(config)
  return UsersLDAP.new(config)
end
