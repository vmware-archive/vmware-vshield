# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_switch).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Prepare switch for VXLAN.'

  def vxlan_switch
    @vxlan_switch ||= begin
      switch_config = {}
      switch_url = '/api/2.0/vdn/switches'
      results = ensure_array( nested_value(get("#{switch_url}"), %w{vdsContexts vdsContext}))
      name = resource[:switch]['name']

      switch_config = results.find{|vdsContext| vdsContext['switch']['name'] == name}
      switch_config
    end
  end

  def exists?
    vxlan_switch
  end

  def replace_properties
    data = {}
    Puppet::Type.type(:vshield_vxlan_switch).parameters.collect.reject{|x| x.to_s =~ /(name|path|scope_name|provider)/}.each do |prop|
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
    post_url = 'api/2.0/vdn/switches'
    post("#{post_url}", { 'vdsContext' => replace_properties } )
  end

  def destroy
    delete("api/2.0/vdn/switches/#{vxlan_switch['switch']['objectId']}")
  end

end
