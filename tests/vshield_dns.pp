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

vshield_dns { 'd5p0v1mgmt-vse-pub':
  dns_servers => [ '10.0.0.1', '10.0.0.2' ],
  enabled     => 'true',
  transport   => Transport['vshield'],
}
