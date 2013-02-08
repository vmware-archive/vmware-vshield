require 'pathname'
vmware_module = Puppet::Module.find('vmware', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_loadbalancer_pool) do
  @doc = 'Manage vShield loadbalancers pools, these are then used by vips'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'loadbalancer name'
  end

   newproperty(:service_port, :parent => Puppet::Property::VMware_Array, :sort => lambda {|a, b| a['protocol'] <=> b['protocol']} ) do
    desc 'these are service_ports that define the protocol/healthcheck/algorithm that the pool will use'
    defaultto([])
  end

   newproperty(:member, :parent => Puppet::Property::VMware_Array, :sort => lambda {|a, b| a['ipAddress'] <=> b['ipAddress']} ) do
    desc 'these are members of the load balancer pool'
    defaultto([])
  end

  newparam(:scope_name) do
    desc 'scope name which will be used with scope_type to get/set loadbalancers'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
