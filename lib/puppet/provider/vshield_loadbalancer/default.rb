# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_loadbalancer).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield load balancer global settings'


  def replace_properties
    [ 'enabled' ].each do |setting|
      @lb_settings["#{setting}"] = resource[:"#{setting}"].to_s if resource[:"#{setting}"]
    end
  end

  def enabled
    @lb_settings = nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config"), [ 'loadBalancer' ])
    value = @lb_settings['enabled']
    value = :true  if TrueClass  === value
    value = :false if FalseClass === value
    value
  end

  def enabled=(enabled=resource[:enabled])
    @pending_changes = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "LB Settings not found for: #{resource[:name]}" unless @lb_settings
      replace_properties
      put("api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config", { 'loadBalancer' => @lb_settings } )
    end
  end
end
