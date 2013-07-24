# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_ha) do
  @doc = 'Manage vShield ha settings'

  validate do
    fail("property: 'enabled' must be set") if not self[:enabled]

    if self[:ip_addresses] and self[:enabled] == :false
      fail("property: 'enabled' set to 'false','ip_addresses' is invalid")
    end

    self[:ip_addresses].each do |value|
      fail("value must be an valid ip") unless value.to_s =~ /^\d+\.\d+\.\d+\.\d+\/?3?0?/
    end

    if self[:datastore_name] and self[:enabled] == :false
      fail("property 'enabled' is not set to 'true', datastore_name is invalid")
    end

    if self[:datastore_name] and not self[:datacenter_name]
      fail("property 'datacenter_name' is not defined, datastore_name requires this")
    end
  end

  newparam(:scope_name, :namevar => true) do
    desc 'name of the vshield edge to enable ha on'
  end

  newproperty(:enabled) do
    desc 'whether or not this service should be enabled'
    newvalues(:false, :true)
  end

  newproperty(:ip_addresses, :array_matching => :all, :sort => :false, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are the ips used for the keepalive communication between edge appliances for ha'
    munge do |value|
      value = value + '/30' if value !~ /\/30$/
    end
    defaultto([])
  end

  newproperty(:declare_dead_time) do
    desc 'this is value in which vshield will consider the ha node dead if not responsive'
    newvalues(/^\d+$/)
    defaultto(6)
  end

  newproperty(:vnic) do
    desc 'vnic to be used for the ha communication'
  end

  newparam(:datacenter_name) do
    desc 'datacenter to be used if setting datastore_name or compute_name'
  end

  newproperty(:datastore_name, :array_matching => :all, :sort => :false, :parent => Puppet::Property::VMware_Array ) do
    desc 'datastores to be used for the appliances. The 2 datastore names
          specified are assumed in order, so first element is 
          appliance 0 and second element is appliance 1'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
