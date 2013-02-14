# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_application_group) do
  @doc = 'Manage vShield application_groups, these are used by fw rules'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'application_group name'
  end

  newproperty(:application_member, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'application ( service ) member(s) of the application_group'
  end

  newproperty(:application_group_member, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are application_group(s) that can be members of existing application_groups'
  end

  newparam(:scope_type) do
    desc 'scope type, this can be either datacenter or edge'
    newvalues(:edge, :datacenter)
    defaultto(:edge)
  end

  newparam(:scope_name) do
    desc 'scope name which will be used with scope_type to get/set application_groups'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
