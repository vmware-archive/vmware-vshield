# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_vxlan_segment) do
  @doc = 'Manage vShield VXLAN Segment IDs.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'switch name'

    #munge do |value|
    #  @resource[:name], @resource[:edge_name] = value.split(':',2)
    #  value
    #end

    newvalues(/\w/)
  end

  newparam(:id) do
    desc 'segment id'
    newvalues(/d*/)
  end

  newparam(:desc) do
    desc 'segment description'
    newvalues(/(...)/)
  end

  newparam(:begin) do
    desc 'starting range for segment'
    newvalues(/d*/)
  end

  newparam(:end) do
    desc 'ending range for segment'
    newvalues(/d*/)
  end

end