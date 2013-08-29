# Copyright (C) 2013 VMware, Inc.

provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_edge_syslog).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield edge syslog service.'

  def edge_syslog
    @edge_syslog ||= begin
      url     = "/api/3.0/edges/#{vshield_edge_moref}/syslog/config"
      results = nested_value(get("#{url}"), [ 'syslog' ] )
      # set a blank array if serverAddresses does not exist
      results['serverAddresses']              = {} if not results['serverAddresses']
      results['serverAddresses']['ipAddress'] =  ensure_array(results['serverAddresses']['ipAddress']) 
      results
    end
  end

  Puppet::Type.type(:vshield_edge_syslog).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      if prop.to_s == 'server_addresses'
        v = edge_syslog[camel_prop]['ipAddress']
      else
        v = edge_syslog[camel_prop]
      end
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      if prop.to_s == 'server_addresses'
        edge_syslog['serverAddresses']['ipAddress'] = value
      else
        edge_syslog[camel_prop] = value
      end
      @pending_changes = true
    end
  end
  
  def flush
    if @pending_changes
      raise Puppet::Error, "Syslog Settings not found for #{resource[:name]}" unless edge_syslog
      data          = {}
      data[:syslog] = edge_syslog.reject{|k,v| v.nil? }
      
      Puppet.debug("Updating syslog settings for edge: #{resource[:name]}")
      put("api/3.0/edges/#{vshield_edge_moref}/syslog/config", data )
    end
  end
end
