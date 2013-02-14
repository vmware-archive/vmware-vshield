# Copyright (C) 2013 VMware, Inc.
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
     #application_group_member => [ 'another_application_group' ], # if applicable
     scope_type               => 'edge',
     scope_name               => 'd5p0v1mgmt-vse-pub',
     transport                => Transport['vshield'],
}
