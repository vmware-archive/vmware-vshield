# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_switch) do
  @doc = 'Prepare switch for VXLAN Virtual Wires.'

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    desc "The path to the dvswitch."
    newvalues(/\w/)
  end

  newparam(:switch, :parent => Puppet::Property::VMware_Hash) do
    desc 'switch id'
  end

  newparam(:teaming) do
    desc 'switch teaming type'
    munge do |value|
      value.upcase
    end
  end

  newparam(:mtu) do
    desc 'mtu for switch'
    defaultto(1600)
    newvalues(/\d/)

    validate do |value|
        raise ArgumenteError, "%s should be great than 1500" % value if value < '1500'
    end
  end

  newparam(:datacenter_name, :parent => Puppet::Property::VMware) do
    newvalues(/\w/)
  end

  autorequire(:transport) do
    self[:name]
  end

end
