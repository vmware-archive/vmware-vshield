# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_global_config) do
  @doc = 'Manage vShield global config.'

  newparam(:host, :namevar => true) do
    desc 'vShield hostname or ip address.'
  end

  newproperty(:vc_info, :parent => Puppet::Property::VMware_Hash) do
    def insync?(is)
      # vSphere API does not return the password, so we need to assume correct.
      desire = @should.first.clone
      is['password'] = desire['password'] if desire.include? 'password'
      super(is)
    end
  end

  newproperty(:host_info, :parent => Puppet::Property::VMware_Hash) do
  end

  newproperty(:dns_info, :parent => Puppet::Property::VMware_Hash) do
  end

  newproperty(:time_info, :parent => Puppet::Property::VMware_Hash) do
  end
end
