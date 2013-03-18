# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_multicast) do
  @doc = 'Manage vShield VXLAN Multicast Address Ranges.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'switch name'
    newvalues(/\w/)
  end

  newparam(:id) do
    desc 'segment id'
    newvalues(/d*/)
  end

  newparam(:desc) do
    desc 'segment id'
    newvalues(/(...)/)
  end

  newparam(:begin) do
    desc 'segment id'
    newvalues(/d*/)
  end

  newparam(:end) do
    desc 'segment id'
    newvalues(/d*/)
  end

end