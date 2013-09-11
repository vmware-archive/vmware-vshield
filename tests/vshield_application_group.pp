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

Vshield_application_group {
  transport => Transport['vshield'],
}

vshield_application { 'puppet':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '8140' ],
  scope_type           => 'global',
  scope_name           => 'global',
  transport            => Transport['vshield'],
}

vshield_application_group { 'puppet_and_smtp':
  ensure             => present,
  application_member => [ 'puppet', 'SMTP' ],
  scope_type         => 'edge',
  scope_name         => $edge['name']
} ->

vshield_application_group { 'test':
  ensure             => present,
  application_member => [ 'HTTPS' ],
  scope_type         => 'edge',
  scope_name         => $edge['name']
} ->

vshield_application_group { 'puppet_and_smtp_and_https':
  ensure                   => present,
  application_group_member => [ 'puppet_and_smtp', 'test' ],
  scope_type               => 'edge',
  scope_name               => $edge['name']
} ->

vshield_application_group { 'global_puppet_and_smtp_and_https':
  ensure                   => present,
  application_member => [ 'puppet', 'SMTP' ],
  scope_type               => 'global',
  scope_name               => 'global',
}
