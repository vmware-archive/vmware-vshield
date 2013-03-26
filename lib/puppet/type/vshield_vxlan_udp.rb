# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_udp) do
  @doc = 'Manage VXLAN Virtual Wire UDP port.'

  newparam(:host, :namevar => true) do
    desc 'vShield hostname or ip address.'
    newvalues(/\w/) 
  end

  newproperty(:vxlan_udp_port, :parent => Puppet::Property::VMware) do
    desc 'UDP Port for VXLAN Virtual Wire'
    newvalues(/\d/)
  end

  autorequire(:vshield_vxlan) do
    self[:name]
  end

  autorequire(:transport) do
    self[:host]
  end

end
