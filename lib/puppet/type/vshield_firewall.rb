require 'pathname'
vmware_module = Puppet::Module.find('vmware', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_firewall) do
  @doc = 'Manage vShield firewall rules, firewall rules consist of:
    source/destination - consists of vshield_ipset or vshield built-in properties ( example: vnic[0-9], internal, external, vse, etc ), note: source port feature is not currently implemented
    service - consists of vshield_application ( service_application ) and vshield_application_group ( service_group )
    action - accept/reject '

  ensurable

  newparam(:name, :namevar => true) do
    desc 'firewall name'
  end

  newproperty(:source, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are source ipset(s) / vnics that can be members of firewall rules, the default is any'
    defaultto([])
  end

  newproperty(:destination, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are destination ipset(s) / vnics that can be members of firewall rules, the default is any'
    defaultto([])
  end

  newproperty(:service_application, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are destination service(s) that are applications only, the default is any, it was decided to split up services into service_application and service_groups since name space conflicts could occur between a service_application and a service_group'
    defaultto([])
  end

  newproperty(:service_group, :array_matching => :all, :parent => Puppet::Property::VMware_Array ) do
    desc 'these are destination service(s) that are application groups only, the default is any, see note on service_application about splitting up service into two seperate properties'
    defaultto([])
  end

  newproperty(:action) do
    desc 'this is the action to take, can be either accept or deny, default is accept'
    newvalues(:accept, :deny)
    defaultto(:accept)
  end

  #newproperty(:log) do
  #  desc 'this is whether or not the rule will log, can be either true or false, default is false'
  #  newvalues(:true, :false)
  #  defaultto(:false)
  #end

  newparam(:scope_name) do
    desc 'scope name which will be used with scope_type to get/set firewalls'
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

  # the below are the ingredients of a single firewall rule
  autorequire(:vshield_ipset) do
    self[:name]
  end

  autorequire(:vshield_application) do
    self[:name]
  end

  autorequire(:vshield_application_group) do
    self[:name]
  end

end
