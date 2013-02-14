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

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

vshield_edge { "${vshield['server']}:${edge['name']}":
  ensure           => present,
  datacenter_name  => $dc1['name'],
  compute          => $cluster1['name'],
  enable_aesni     => false,
  enable_fips      => false,
  enable_tcp_loose => false,
  vse_log_level    => 'info',
  fqdn             => $edge['fqdn'],
  vnics            => $edge['vnics'],
  transport  => Transport['vshield'],
}
