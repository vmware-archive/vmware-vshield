# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

vshield_firewall_default_policy { $edge['name']:
  action             => 'deny',
  logging_enabled    => false,
  transport          => Transport['vshield'],
}
