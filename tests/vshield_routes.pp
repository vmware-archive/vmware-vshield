# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

vshield_routes { $edge['name']:
  default_route => $default_route,
  static_routes => $static_routes,
  transport   => Transport['vshield'],
}

