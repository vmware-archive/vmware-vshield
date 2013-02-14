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

Vshield_ipset {
  transport => Transport['vshield'],
}

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

vshield_ipset { 'demo':
  ensure     => present,
  value      => [ '10.10.10.1', '10.1.1.1', '10.1.1.2' ],
  scope_name => $dc1['name'],
  scope_type => 'datacenter',
}

vshield_ipset { 'demo2':
  ensure     => absent,
  value      => [ '10.10.10.1' ],
  scope_name => $dc1['name'],
  scope_type => 'datacenter',
}
