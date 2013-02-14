# Copyright (C) 2013 VMware, Inc.
transport { 'vshield':
  username => 'admin',
  password => 'default',
  server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
}

transport { 'vcenter':
  username => 'root',
  password => 'vmware',
  server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
}

vshield_ipset { 'web1':
  value      => [ '10.10.10.1' ],
  scope_type => 'edge',
  scope_name => 'd5p0v1mgmt-vse-pub',
  transport  => Transport['vshield'],
}

vshield_application_group { 'puppet_and_smtp':
     ensure               => present,
     application_member   => [ 'puppet', 'SMTP' ],
     scope_type           => 'edge',
     scope_name           => 'd5p0v1mgmt-vse-pub',
     transport            => Transport['vshield'],
}

vshield_firewall {'dmz-to-puppet':
  ensure              => present,
  source              => [ 'demo'],   
  destination         => [ 'web1' ],
  service_application => [ 'HTTP' ],
  action              => 'accept',
  #log                 => 'false',
  scope_name          => 'd5p0v1mgmt-vse-pub',
  require             => Vshield_ipset['web1'],
  transport           => Transport['vshield'],
}

vshield_firewall {'service_group_test':
  ensure              => present,
  source              => [ 'demo'],   
  destination         => [ 'web1' ],
  service_application => [ 'HTTPS' ],
  service_group       => [ 'puppet_and_smtp' ],
  action              => 'accept',
  #log                 => 'false',
  scope_name          => 'd5p0v1mgmt-vse-pub',
  require             => [ Vshield_ipset['web1'], Vshield_application_group['puppet_and_smtp'] ],
  transport           => Transport['vshield'],
}
