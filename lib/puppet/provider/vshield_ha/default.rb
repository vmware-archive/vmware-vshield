# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_ha).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield ha service.'

  def edge_ha
    @edge_ha ||= begin
      ha_url  = "/api/3.0/edges/#{vshield_edge_moref}/highavailability/config"
      ha_config = nested_value(get("#{ha_url}"), [ 'highAvailability' ] )
      ha_config['vnic']                   ||= '' 
      ha_config['ipAddresses']            ||= {} 
      ha_config['ipAddresses']['ipAddress'] = ensure_array(ha_config['ipAddresses']['ipAddress'])
      ha_config
    end
  end

  Puppet::Type.type(:vshield_ha).properties.collect{|x| x.name}.reject{|x| x == :ensure or x == :ip_addresses}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      v = edge_ha[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      validate_vnic(value) if prop == 'vnic'
      @pending_changes = true
      edge_ha[camel_prop] = value
    end
  end
  
  def ip_addresses
    edge_ha['ipAddresses']['ipAddress'].sort
  end

  def ip_addresses=(value)
    @pending_changes = true
    edge_ha['ipAddresses']['ipAddress'] = value
  end

  def validate_vnic(vnic)
    vnic_url   = "api/3.0/edges/#{vshield_edge_moref}/vnics"
    cur_vnics  = nested_value(get("#{vnic_url}"), [ 'vnics', 'vnic' ] )
    result     = cur_vnics.find{|x| x['index'] == vnic.to_s }

    error_msg  = "vnic: #{vnic} not found for: #{resource[:name]}"
    raise Puppet::Error, "#{error_msg}" if result.nil?
    error_msg  = "vnic: #{vnic} isConnected must be set to true"
    raise Puppet::Error, "#{error_msg}" if not result['isConnected'] == true
    error_msg  = "vnic: #{vnic} type must be internal"
    raise Puppet::Error, "#{error_msg}" if not result['type'] == 'internal'
  end

  def get_appliances
    appl_url    = "/api/3.0/edges/#{vshield_edge_moref}/appliances" 
    @appliances = ensure_array(nested_value(get("#{appl_url}"), [ 'appliances', 'appliance' ]))
    @appliances = @appliances.sort {|a,b| a['highAvailabilityIndex'] <=> b['highAvailabilityIndex']}
  end

  def datastore_name
    get_appliances
    ensure_array(@appliances.collect{|x| x['datastoreName']})
  end

  def datastore_name=(value)
    @appliance_changes = true
  end

  def datacenter(name)
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{name}' not found."
  end

  def compute(dc,name)
    dc.find_compute_resource(name) or raise Puppet::Error, "compute '#{name}' not found."
  end

  def datastore(dc,name)
    dc.find_datastore(name) or raise Puppet::Error, "datastore #{name} not found"
  end

  def flush
    if @pending_changes
      error_msg = "HA Settings not found for #{resource[:name]}"
      raise Puppet::Error, "#{error_msg}" unless edge_ha
      data                     = {}
      data[:highAvailability]  = edge_ha.reject{|k,v| v.nil? }
      
      Puppet.debug("Updating ha settings for edge: #{resource[:name]}")
      put("api/3.0/edges/#{vshield_edge_moref}/highavailability/config", data )
    end
    if @appliance_changes
      @appliances.each_with_index do |cur_appl,index|
        appl_ha_index = cur_appl['highAvailabilityIndex']
        index_err     = "index; #{index} != haIndex: #{appl_ha_index}" 
        raise Puppet::Error, "#{index_err}" if appl_ha_index.to_s != index.to_s
        dc       = datacenter(resource[:datacenter_name])
        new_appl = cur_appl.clone
        if resource[:datastore_name] and resource[:datastore_name][index]
          ds = resource[:datastore_name][index]
          new_appl.delete('datastoreName')
          new_appl['datastoreId']    = datastore(dc,ds)._ref
        end
        if cur_appl != new_appl
          Puppet.debug("Updating appliance: haindex = #{index}")
          appl_url = "/api/3.0/edges/#{vshield_edge_moref}/appliances/#{appl_ha_index}"
          put("#{appl_url}", {:appliance => new_appl} )
        end
      end
    end
  end
end
