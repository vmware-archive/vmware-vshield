# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_ha).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield ha service.'
  
  def enabled
    ha_url   = "/api/3.0/edges/#{vshield_edge_moref}/highavailability/config"
    @edge_ha = nested_value(get("#{ha_url}"), [ 'highAvailability' ] )

    @edge_ha['vnic']                   ||= '' 
    @edge_ha['ipAddresses']            ||= {} 
    @edge_ha['ipAddresses']['ipAddress'] = ensure_array(@edge_ha['ipAddresses']['ipAddress'])

    value = @edge_ha['enabled']
    value = :true  if TrueClass  === value
    value = :false if FalseClass === value
    value
  end

  def ip_addresses
    @edge_ha['ipAddresses']['ipAddress'].sort
  end

  def ip_addresses=(value)
    @pending_changes = true
  end

  def enabled=(value)
    @pending_changes = true
  end

  def declared_dead_time
    @edge_ha['declareDeadTime']
  end

  def declared_dead_time=(value)
    @pending_changes = true
  end

  def vnic
    @edge_ha['vnic']
  end

  def vnic=(value)
    @pending_changes = true
  end

  def validate_vnic(vnic)
    vnic_url   = "api/3.0/edges/#{vshield_edge_moref}/vnics"
    cur_vnics  = nested_value(get("#{vnic_url}"), [ 'vnics', 'vnic' ] )
    result     = cur_vnics.find{|x| x['index'] == vnic }

    error_msg  = "vnic: #{vnic} not found for: #{resource[:name]}"
    raise Puppet::Error, "#{error_msg}" if result.nil?
    error_msg  = "vnic: #{vnic} isConnected must be set to true"
    raise Puppet::Error, "#{error_msg}" if not result['isConnected'] == true
    error_msg  = "vnic: #{vnic} type must be internal"
    raise Puppet::Error, "#{error_msg}" if not result['type'] == 'internal'
  end

  def appliances
    appl_url    = "/api/3.0/edges/#{vshield_edge_moref}/appliances" 
    appls = ensure_array(nested_value(get("#{appl_url}"), [ 'appliances', 'appliance' ]))
    appls.sort {|a,b| a['highAvailabilityIndex'] <=> b['highAvailabilityIndex']}
  end

  def datastore_name
    ensure_array(appliances.collect{|x| x['datastoreName']})
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
      raise Puppet::Error, "#{error_msg}" unless @edge_ha
      @edge_ha['ipAddresses']['ipAddress'] = resource[:ip_addresses]
      @edge_ha['enabled']                  = resource[:enabled].to_s

      if resource[:vnic]
        @edge_ha['vnic']                   = resource[:vnic].to_s
        validate_vnic(resource[:vnic])
      end

      data                                 = {}
      data[:highAvailability]              = @edge_ha.reject{|k,v| v.nil? }
      
      Puppet.debug("Updating ha settings for edge: #{resource[:name]}")
      put("api/3.0/edges/#{vshield_edge_moref}/highavailability/config", data )
    end
    if @appliance_changes
      appliances.each_with_index do |cur_appl,index|
        appl_ha_index = cur_appl['highAvailabilityIndex']
        index_err     = "index; #{index} != haIndex: #{appl_ha_index}" 
        raise Puppet::Error, "#{index_err}" if appl_ha_index.to_s != index.to_s
        dc       = datacenter(resource[:datacenter_name])
        # this works around when drs is violating contraints will show error
        cur_appl.delete('datastoreName')
        new_appl = cur_appl.clone
        if resource[:datastore_name] and resource[:datastore_name][index]
          ds = resource[:datastore_name][index]
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
