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

vshield_application { 'puppet':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '8140' ],
  scope_type           => 'edge',
  scope_name           => $edge['name'],
  transport            => Transport['vshield'],
}

vshield_application { 'tcp-5672':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '5672' ],
  scope_type           => 'edge',
  scope_name           => $edge['name'],
  transport            => Transport['vshield'],
}

vshield_application { 'global-tcp-5672':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '5672' ],
  scope_type           => 'global',
  scope_name           => 'global',
  transport            => Transport['vshield'],
}
