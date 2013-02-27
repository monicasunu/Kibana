require 'net/ldap'

class AuthLDAP
  # Required function, accepts a KibanaConfig object
  def initialize(config)
    @ldap = Net::LDAP.new
    @ldap_key = ""
    @ldap.host = (defined? config::Ldap_host) ? config::Ldap_host : ""
    @ldap.port = (defined? config::Ldap_port) ? config::Ldap_port : 636
    @ldap_user_base = (defined? config::Ldap_user_base) ? config::Ldap_user_base : ""
    @ldap_group_base = (defined? config::Ldap_group_base) ? config::Ldap_group_base : ""
    @ldap_suffix = (defined? config::Ldap_domain_fqdn) ? "@" + config::Ldap_domain_fqdn : ""
    @ldap.encryption(:simple_tls)
  end

  # Required function, authenticates a username/password
  def authenticate(username,password)
    begin
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
