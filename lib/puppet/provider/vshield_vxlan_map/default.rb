# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_map).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manage VXLAN cluster switch mappings.'

  def vxlan_map
    @vxlan_map ||= begin
      map_config = {}
      map_url = '/api/2.0/vdn/map/cluster'
      results = ensure_array( nested_value(get("#{map_url}"), %w{clusterMappings clusterMapping clusterMappingSpec}))
      vlan = resource[:vlan_id]
      map_config = results.find{|clusterMappingSpec| clusterMappingSpec['vlanId'] == vlan}
    end
  end

  Puppet::Type.type(:vshield_vxlan_map).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      v = vxlan_map[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      vxlan_map[camel_prop] = value
      @pending_changes = true
    end
  end

  def exists?
    vxlan_map
  end

  def replace_properties
    data = {}
    data['vlanId'] = resource[:vlan_id]
    Puppet::Type.type(:vshield_vxlan_map).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
      end
    end
    data['switch']['objectId'] = dvswitch._ref
    data['switch']['objectTypeName'] = dvswitch.class
    data
  end

  def create
    cluster_id = cluster._ref
    post_url = "api/2.0/vdn/map/cluster/#{cluster_id}"
    post("#{post_url}", { 'clusterMappingSpec'  => replace_properties } )
  end

  def cluster(name=resource[:cluster_name])
    datacenter.find_compute_resource(name) or raise Puppet::Error, "cluster '#{name}' not found."
  end

end