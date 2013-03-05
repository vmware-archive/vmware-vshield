# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

vshield_ha { $edge['name']:
  ip_addresses    => [ '192.168.0.1', '192.168.0.2' ],
  enabled         => 'true',
  vnic            => 1,
  datastore_name  => [ 'ns120-lun0', 'ns120-lun1' ],
  datacenter_name => 'd5p0',
  transport       => Transport['vshield'],
  require         => [ Transport['vshield'], Transport['vcenter'] ]
}
