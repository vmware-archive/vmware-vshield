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

vshield_application_group { 'puppet_and_smtp':
     ensure               => present,
     application_member       => [ 'puppet', 'SMTP' ],
     scope_type               => 'edge',
     scope_name               => 'd5p0v1mgmt-vse-pub',
     transport                => Transport['vshield'],
}

vshield_application_group { 'test':
     ensure               => present,
     application_member       => [ 'HTTPS' ],
     scope_type               => 'edge',
     scope_name               => 'd5p0v1mgmt-vse-pub',
     transport                => Transport['vshield'],
}


vshield_application_group { 'puppet_and_smtp_and_https':
     ensure               => present,
     #application_member       => [ 'HTTPS' ],
     application_group_member => [ 'puppet_and_smtp', 'test' ],
     scope_type               => 'edge',
     scope_name               => 'd5p0v1mgmt-vse-pub',
     require                  => [ Vshield_application_group['test'],  Vshield_application_group['puppet_and_smtp'] ],
     transport                => Transport['vshield'],
}
