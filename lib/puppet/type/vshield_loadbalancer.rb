# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_loadbalancer) do
  @doc = 'Manage vShield loadbalancer global settings'

  newparam(:scope_name, :namevar => true) do
    desc 'loadbalancer name'
  end

  newproperty(:enabled) do
    desc 'whether or not the load balancing service is enabled'
    newvalues(:true,:false)
    defaultto(:false)
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
