# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_switch) do
  @doc = 'Prepare switch for VXLAN Virtual Wires.'

  ensurable

  newparam(:name, :namevar => true) do
    desc "The path to the dvswitch."
    newvalues(/\w/)
  end

  newparam(:switch, :parent => Puppet::Property::VMware_Hash) do
    desc 'switch id'
    #newvalues(/\d+/)
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
    newvalues(/\d+/)
  end

  newparam(:datacenter_name, :parent => Puppet::Property::VMware) do
  end

end