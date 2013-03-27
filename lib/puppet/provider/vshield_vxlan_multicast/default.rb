# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_multicast).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manage VXLAN Multicast Address Ranges.'

  def vxlan_multicast
    @vxlan_multicast ||= begin
      multicast_config = {}
      multicast_url = '/api/2.0/vdn/config/multicasts'
      results = ensure_array( nested_value(get(multicast_url), %w{multicastRanges multicastRange}))
      name = resource[:name]
      multicast_config = results.find{|multicastRange| multicastRange['name'] == name}
    end
  end

  def exists?
    vxlan_multicast
  end

  def replace_properties
    data = {}
    Puppet::Type.type(:vshield_vxlan_multicast).parameters.collect.reject{|x| x.to_s =~ /(scope_name|provider)/}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
      end
    end
    data
  end

  def create
    post_url = 'api/2.0/vdn/config/multicasts'
    post(post_url, { 'multicastRange'  => replace_properties } )
  end

  def destroy
    delete("api/2.0/vdn/config/multicasts/#{vxlan_multicast['id']}")
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "multicast address range not found for #{resource[:name]}" unless vxlan_multicast
      data    = vxlan_multicast.update(replace_properties).reject{|k,v| v.nil?}

      put_url = "api/2.0/vdn/config/multicasts/#{vxlan_multicast['id']}"
      Puppet.debug("Updating multicast address range for edge: #{resource[:name]}")
      put(put_url, {'multicastRange' => data})
    end
  end

end
