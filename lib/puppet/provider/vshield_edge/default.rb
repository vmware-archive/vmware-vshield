# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_edge).provide(:vshield_edge, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield edge.'

  { :enable_aesni     => 'aesni?enable=',
    :enable_fips      => 'fips?enable=',
    :enable_tcp_loose => 'tcploose?enable=',
    :vse_log_level    => 'logging?level='
  }.each do |property, request|
    camel_prop = PuppetX::VMware::Util.camelize(property, :lower).to_sym
    request ||= property.to_s.sub(/^enable_/,'').sub(/_/, '') + '?enable='

    define_method(property) do
      value = edge_detail[camel_prop.to_s]
      if (value.is_a? TrueClass) || (value.is_a? FalseClass)
        value ? :true : :false
      else
        value
      end
    end

    define_method("#{property}=".to_sym) do |value|
      post("api/3.0/edges/#{@instance['id']}/#{request}#{value}", {})
    end
  end

  # add index and substitute the portgroup name with the moref
  def process_vnic
    all_vnics = []
    resource[:vnics].each_with_index do |vnic,index|
      vnic['portgroupId'] = portgroup_moref(vnic['portgroupName'])
      vnic['index']       = index
      all_vnics << vnic
    end
    all_vnics
  end

  def exists?
    result    = edge_summary || []
    @instance = result.find{|x| x['name'] == resource[:edge_name]}
  end

  def create
    appliance = {
      :resourcePoolId => resource_pool.resourcePool._ref,
      :datastoreId => datastore._ref,
    }
    data = {
      :datacenterMoid => datacenter._ref,
      :name => resource[:edge_name],
      :description => 'VShield Edge managed by Puppet',
      # TODO: not sure if we ever get more than one:
      :appliances => {
        :applianceSize => resource[:appliance_size],
        :appliance => appliance.merge(resource[:appliance] || {}),
      },
    } 

    if resource[:vnics]
      vnic = process_vnic
      data[:vnics] = { :vnic => vnic }
    end

    order =  [:datacenterMoid, :name, :description, :tenant, :fqdn, :vseLogLevel, :enableAesni, :enableFips, :enableTcpLoose, :appliances, :vnics]
    data[:order!] = order - (order - data.keys)
    post("api/3.0/edges",:edge => data)
  end

  def destroy
    delete("api/3.0/edges/#{@instance['id']}")
  end

  def portgroup_moref(portgroup)
    result = datacenter.network.find{|pg| pg.name == portgroup }
    raise(Puppet::Error, "Fatal Error: Portgroup: '#{portgroup}' was not found") if result.nil?
    result._ref
  end

  def vnics
    vnic_url = "api/3.0/edges/#{@instance['id']}/vnics"
    result = ensure_array(nested_value(get("#{vnic_url}"), [ 'vnics', 'vnic' ]) )
    # all vnics are pre configured, chose connected vnics to distinguish between used/unused
    @vnics = ensure_array(result.find_all{|x| x['isConnected'] == true})
  end

  def next_avail_vnic
    vnic_url        = "api/3.0/edges/#{@instance['id']}/vnics"
    result          = ensure_array(nested_value(get("#{vnic_url}"), [ 'vnics', 'vnic' ]) )
    next_vnic       = result.find{|x| x['isConnected'] == false} 
    next_vnic_error = "Next available vnic who's status is 'not connected' was not found",
                      " one thing to check is if all vnics are allocated"
    raise Puppet::Error, "#{next_vnic_error}" if next_vnic.nil?
    next_vnic
  end

  def vnics=(nics)
    resource[:vnics].each do |new_vnic|
      cur_vnic = @vnics.find{|x| x['name'] == new_vnic['name']} 
      # add or update the vnic
      if cur_vnic.nil?
        new_vnic['portgroupId'] = portgroup_moref(new_vnic['portgroupName'])
        new_vnic['index']       = next_avail_vnic['index']
        vnic_url                = "/api/3.0/edges/#{@instance['id']}/vnics/?action=patch"

        Puppet.debug("Adding vnic#{new_vnic['index']}")
        post("#{vnic_url}", {:vnics => {:vnic => new_vnic} } )
      else
        data        = {}
        data[:vnic] = cur_vnic.merge(new_vnic)
        vnic_url    = "/api/3.0/edges/#{@instance['id']}/vnics/#{cur_vnic['index']}"

        Puppet.debug("Updating vnic: #{new_vnic.inspect}")
        put("#{vnic_url}", data )
      end
    end
  end

  private

  def datacenter(name=resource[:datacenter_name])
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{name}' not found."
  end

  def resource_pool(name=resource[:resource_pool_name])
    datacenter.find_compute_resource(name) or raise Puppet::Error, "resource_pool resource '#{name}' not found."
  end

  def datastore
    if resource[:datastore_name]
      datacenter.find_datastore(resource[:datastore_name])
    else
      resource_pool.datastore.first
    end
  end
end

