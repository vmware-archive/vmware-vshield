# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_syslog) do
  @doc = 'Manage vShield syslog config.'

  newparam(:host, :namevar => true) do
    desc 'vShield hostname or ip address.'
  end

  newparam(:server_info) do
    desc 'no longer implemented, please use syslog_server and port instead'
    validate do |value|
      raise('no longer implemented, please use syslog_server and port instead')
    end
  end

  newproperty(:syslog_server, :parent => Puppet::Property::VMware) do
    newvalues(/\w+/)
    validate do |value|
      msg = "Error, in order to accomodate 6.x changes, port has been split out to 'port', please use this instead"
      raise(msg) if value =~ /:/
    end
  end

  newproperty(:port, :parent => Puppet::Property::VMware) do
    desc "syslog port, defaults to 514"
    newvalues(/^\d+$/)
    defaultto(514)
  end

  newproperty(:protocol, :parent => Puppet::Property::VMware) do
    desc "syslog protocol, valid values are UDP/TCP/UDP6/TCP6, defaults to UDP, only available in > 6.x"
    newvalues(:udp, :tcp, :UDP, :TCP, :udp6, :tcp6, :UDP6, :TCP6)
    munge do |value|
      value.upcase
    end
  end

  autorequire(:transport) do
    self[:host]
  end
end
