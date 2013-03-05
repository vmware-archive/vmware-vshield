# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vshield_nat) do
  @doc = 'Manage vShield nat rules'

  ensurable

  validate do 
    scope_msg  = "scope_name(edge_name) must be specified" 
    fail("#{scope_msg}") if not self[:scope_name]
    action_msg = "action(dnat/snat) must be specified" 
    fail("#{action_msg}") if not self[:action]
    vnic_msg   = "vnic([0-9]) must be specified" 
    fail("#{vni_msg}") if not self[:scope_name]
    trans_msg  = "translated_address must be specified" 
    fail("#{trans_msg}") if not self[:scope_name]

    if self[:action] == 'snat'
      snat_msg   = "snat does not support use of protocol"
      fail("#{snat_msg}") if self[:protocol]
      snat_msg   = "snat does not support use of original port"
      fail("#{snat_msg}") if self[:original_port]
      snat_msg   = "snat does not support use of translated port"
      fail("#{snat_msg}") if self[:translated_port]
    end

    if self[:protocol]
      if self[:protocol] !~ /udp|tcp|udp|udplite|sctp|dccp/
        proto_msg  = "protocol can only use translated/original port with udp/tcp/udp/udplite/sctp/dccp"
        fail("#{proto_msg}") if self[:original_port] or self[:translated_port]
      end
      proto_msg  = "icmp_type can only be used with icmp protocol"
      fail("#{proto_msg}") if self[:protocol] !~ /icmp/ and self[:icmp_type]
    end

  end

  newparam(:original_address, :namevar => true) do
    desc 'original ip/range'
    newvalues(/\d/)
  end

  newproperty(:action) do
    desc 'destination or source nat'
    newvalues(:dnat,:snat)
  end

  newproperty(:vnic) do
    desc 'vnic number to use'
    newvalues(/[0-9]/)
  end

  newproperty(:translated_address) do
    desc 'translated ip/range'
    newvalues(/\d/)
  end

  newproperty(:protocol) do
    desc 'nat protocol to be used, note: for icmp, the icmp_type can be used to specify sub option
          ( example: echo-request )'
    munge do |value|
      value.downcase
    end
  end

  newproperty(:icmp_type) do
    desc 'icmp_type can be used to specify an icmp sub option, example: echo-request'
    munge do |value|
      value.downcase
    end
  end

  newproperty(:enabled) do
    desc 'whether or not enabled, since api defaults to true, so are we'
    newvalues(:true,:false)
    defaultto(:true)
  end

  newproperty(:original_port) do
    desc 'original port, cannot be used with certain protocols or with action: snat'
    newvalues(/^\d+$/)
  end

  newproperty(:translated_port) do
    desc 'translated port, cannot be used with certain protocols or with action: snat'
    newvalues(/^\d+$/)
  end

  newparam(:scope_name) do
    desc 'the edge where this nat is to be configured'
    newvalues(/\w/)
  end

  autorequire(:vshield_edge) do
    self[:name]
  end

end
