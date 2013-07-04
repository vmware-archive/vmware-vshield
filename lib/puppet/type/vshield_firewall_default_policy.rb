# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_firewall_default_policy) do
  @doc = 'Manage vShield firewall default policy
    logging_enabled - whether or not to log when this rule is hit
    action          - accept/reject '

  newparam(:scope_name, :namevar => true) do
    desc 'scope name which will be used with scope_type to get/set firewall default policy'
  end

  newproperty(:logging_enabled) do
    desc 'whether or not logging is enabled'
    newvalues(:true,:false)
    defaultto(:false)
  end

  newproperty(:action) do
    desc 'this is the action to take, can be either accept or deny, default is deny'
    newvalues(:accept, :deny)
    defaultto(:deny)
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
