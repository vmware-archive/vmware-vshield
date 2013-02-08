transport { 'vshield':
  username => 'admin',
  password => 'default',
  server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
}

transport { 'vcenter':
  username => 'root',
  password => 'vmware',
  server   => '10.255.21.105',
}

vshield_application { 'puppet':
     ensure               => present,
     application_protocol => 'TCP',
     value                => [ '8140' ],
     scope_type           => 'edge',
     scope_name           => 'd5p0v1mgmt-vse-pub',
     transport            => Transport['vshield'],
}

#vshield_ipset { 'demo':
#  value  => [ '10.10.10.1', '10.1.1.2', '10.1.1.1' ],
#  scope_name => 'd5p0v1mgmt-vse-pub',
#  scope_type => 'edge',
#  transport => Transport['vshield'],
#}

