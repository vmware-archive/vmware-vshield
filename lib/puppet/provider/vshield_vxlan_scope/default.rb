# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_scope).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manage VXLAN Network Scopes.'

  def vxlan_scope
    @vxlan_scope ||= begin
      scope_config = {}
      scope_url = '/api/2.0/vdn/scopes'
      results = ensure_array( nested_value(get("#{scope_url}"), %w{vdnScopes vdnScope}))
      name = resource[:name]
      scope_config = results.find{|vdnScope| vdnScope['name'] == name}
    end
  end

  Puppet::Type.type(:vshield_vxlan_scope).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      v = vxlan_scope[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      edge_nat[camel_prop] = value
      @pending_changes = true
    end
  end

  def exists?
    vxlan_scope
  end

  def replace_properties
    data = {}
    data['name'] = resource[:name]
    Puppet::Type.type(:vshield_vxlan_scope).properties.collect {|x| x.name}.reject{|x| x == :ensure}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
      end
    end
    data['clusters']['cluster']['cluster']['objectId'] = cluster
    data
  end

  def create
    post_url = 'api/2.0/vdn/scopes'
    post("#{post_url}", { 'vdnScope' => replace_properties } )

  end

  def destroy
    delete("api/2.0/vdn/scopes/#{vxlan_scope['objectId']}")
  end

  def cluster(name=resource[:cluster_name])
    cr = datacenter.find_compute_resource(name) or raise Puppet::Error, "cluster '#{name}' not found."
    cr._ref
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "network scope not found for #{resource[:name]}" unless vxlan_scope
      data    = vxlan_scope.update(replace_properties).reject{|k,v| v.nil?}

      put_url = "api/2.0/vdn/scopes/#{vxlan_scope['objectId']}/attributes"
      Puppet.debug("Updating network scope: #{resource[:name]}")
      put("#{put_url}", {'vdnScope' => data})
    end
  end

end
