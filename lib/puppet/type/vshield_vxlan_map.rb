# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_map) do
  @doc = 'Map a cluster to a vDS.'

  ensurable

  newparam(:vlan_id, :namevar => true) do
    desc 'switch name'
  end

  newproperty(:switch, :parent => Puppet::Property::VMware_Hash) do
    desc 'switch id'
  end

  newparam(:datacenter_name, :parent => Puppet::Property::VMware) do
  end

  newparam(:cluster_name, :parent => Puppet::Property::VMware) do
  end

end