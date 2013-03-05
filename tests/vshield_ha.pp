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
  ip_addresses    => $edge['ha']['ip_addresses'],
  enabled         => 'true',
  vnic            => $edge['ha']['vnic'],
  datastore_name  => $edge['ha']['datastore_name'],
  datacenter_name => $dc1['name'],
  transport       => Transport['vshield'],
  require         => [ Transport['vshield'], Transport['vcenter'] ]
}
