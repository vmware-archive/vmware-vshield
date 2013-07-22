# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_ipset) do
  @doc = 'Manage vShield ipsets, these are used by fw rules'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'ipset name'
  end

  newproperty(:value, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'ipset value, this is a string that can consist of ip addresses, networks, and range of addresses seperated with commas'
  end

  newparam(:scope_type) do
    desc 'scope type, this can be either edge, datacenter, or global. if not specified, edge is the default'
    newvalues(:edge, :datacenter, :global_root, :global)
    defaultto(:edge)
    munge do |value|
      value = 'global_root' if value == 'global'
      value
    end
  end

  newparam(:scope_name) do
    desc 'scope name which will be used with scope_type to get/set ipsets'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
