# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_loadbalancer_vip) do
  @doc = 'Manage vShield loadbalancers vips'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'loadbalancer name'
  end

  newproperty(:application_profile, :parent => Puppet::Property::VMware_Array, :sort => lambda {|a, b| a['protocol'] <=> b['protocol']} ) do
    desc 'these are applications that define the protocol/persistence that the vip will use'
    defaultto([])
  end

  newproperty(:pool) do
    desc 'this is the name of the pool that is used for the vip'
  end

  newproperty(:ip_address) do
    desc 'ip address to use for the vip'
    validate do |value|
      unless value =~ /^\d+\.\d+\.\d+\.\d+$/
        raise ArgumenteError, "%s is not a valid ip address" % value
      end
    end
  end

  newparam(:scope_name) do
    desc 'scope name which will be used with scope_type to get/set loadbalancers'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

  autorequire(:vshield_loadbalancer_pool) do
    self[:name]
  end

end
