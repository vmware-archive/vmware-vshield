# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

vshield_nat { $nat1['description']:
  ensure             => present,
  action             => $nat1['action'],
  vnic               => $nat1['vnic'],
  original_address   => $nat1['original_address'],
  translated_address => $nat1['translated_address'],
  protocol           => 'tcp',
  original_port      => '1',
  translated_port    => '2',
  scope_name         => $edge['name'],
  enabled            => true,
  transport          => Transport['vshield'],
}

vshield_nat { $nat2['description']:
  ensure             => present,
  action             => $nat2['action'],
  vnic               => $nat2['vnic'],
  original_address   => $nat2['original_address'],
  translated_address => $nat2['translated_address'],
  protocol           => 'icmp',
  icmp_type          => 'echo-request',
  scope_name         => $edge['name'],
  transport          => Transport['vshield'],
}
