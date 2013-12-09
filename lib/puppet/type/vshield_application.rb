# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_application) do
  @doc = 'Manage vShield applications, these are used by fw rules'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'application name'
  end

  newproperty(:value, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'application value, this is a string that can consist of port number(s) and ranges of ports'
    munge do |value|
      # since vshield treats these as strings, we are doing the same, this is needed to account for ranges
      value.to_s
    end
  end

  newproperty(:application_protocol) do
    desc 'application protocol, example TCP/UDP/ICMP/IGMP/FTP/etc ( way to many to list, refer to api guide for more available options'
    munge do |value|
      value.upcase
    end
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
    desc 'scope name which will be used with scope_type to get/set applications'
  end

  newparam(:inclusive) do
    desc 'whether the resource value is inclusive'
    defaultto(true)
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
