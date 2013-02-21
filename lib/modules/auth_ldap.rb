require 'net/ldap'

class AuthLDAP
  # Required function, accepts a KibanaConfig object
  def initialize(config)
    @ldap = Net::LDAP.new
<<<<<<< HEAD
    @ldap.host = (defined? config::Ldap_host) ? config::Ldap_host : "127.0.0.1"
    @ldap.port = (defined? config::Ldap_port) ? config::Ldap_port : 389
    @ldap_user_base = (defined? config::Ldap_user_base) ? config::Ldap_user_base : "dc=example, dc=com"
    @ldap_group_base = (defined? config::Ldap_group_base) ? config::Ldap_group_base : "dc=example, dc=com"
    if (defined? config::Ldap_domain_fqdn)
      @ldap_suffix = "@" + config::Ldap_domain_fqdn
      @ldap_prefix = ""
    elsif (defined? config::Ldap_user_attribute)
      @ldap_suffix = "," + @ldap_user_base
      @ldap_prefix = config::Ldap_user_attribute + "="
    else
      @ldap_suffix = ""
      @ldap_prefix = ""
    end
    @auth_admin_user = (defined? config::Auth_Admin_User) ? config::Auth_Admin_User : ""
    @auth_admin_pass = (defined? config::Auth_Admin_Pass) ? config::Auth_Admin_Pass : ""
=======
    @ldap_key = "L1m1t3d!"
    @ldap.host = (defined? config::Ldap_host) ? config::Ldap_host : "dc05-sc.corp.shutterfly.com"
    @ldap.port = (defined? config::Ldap_port) ? config::Ldap_port : 636
    @ldap_user_base = (defined? config::Ldap_user_base) ? config::Ldap_user_base : "CN=svc-giza,OU=Accounts-Service,OU=Controlled Objects,OU=shutterfly,DC=corp,DC=shutterfly,DC=com"
    @ldap_group_base = (defined? config::Ldap_group_base) ? config::Ldap_group_base : "DC=corp,DC=shutterfly,DC=com"
    @ldap_suffix = (defined? config::Ldap_domain_fqdn) ? "@" + config::Ldap_domain_fqdn : ""
    @ldap.encryption(:simple_tls)
>>>>>>> mongo storage, user_ldap, favorite saving,
  end

  # Required function, authenticates a username/password
  def authenticate(username,password)
    begin
<<<<<<< HEAD
      if username == @auth_admin_user and password == @auth_admin_pass
        puts "Bypassing LDAP authentication for Auth_Admin_User"
        return true
      end
      @ldap.auth @ldap_prefix + username + @ldap_suffix, password
      if @ldap.bind
        return true
      end
=======
        @ldap.auth @ldap_user_base, @ldap_key
        @ldap.bind
        filter = Net::LDAP::Filter.eq("sAMAccountName",username)
        result = @ldap.bind_as(:base => @ldap_group_base, :filter => filter, :password => password)
        if result
                #p "true"
                return true
        else
                #p "auth failed"
                return false
        end
>>>>>>> mongo storage, user_ldap, favorite saving,
    rescue
    end
    return false
  end
end

# Required function, returns the auth
# class for this module.
def get_auth_module(config)
  return AuthLDAP.new(config)
end
