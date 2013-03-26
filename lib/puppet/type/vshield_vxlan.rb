# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan) do
  @doc = 'Manage vShield VXLAN Virtual Wires.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'virtual wire name'
    newvalues(/\w/)
  end

  newparam(:description) do
    desc 'virtual wire description'
    newvalues(/.../)
  end

  newparam(:tenant_id) do
    desc 'virtual wire tenant id'
    newvalues(/d*/)
  end

end