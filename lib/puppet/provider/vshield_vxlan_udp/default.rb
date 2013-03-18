# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_udp).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manage VXLAN Virtual Wire UDP port.'

  def vxlan_udp_port
    @vxlan_udp ||= begin
      udp_url = '/api/2.0/vdn/config/vxlan/udp/port'
      result = nested_value( get("#{udp_url}"), 'int')
    end
  end

  def vxlan_udp_port=(value)
    vxlan_udp_port = value
    @pending_changes = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "Settings not found for: #{resource[:vxlan_udp_port]}" unless vxlan_udp_port

      put("api/2.0/vdn/config/vxlan/udp/port/#{resource[:vxlan_udp_port]}",{} )
    end
  end

end