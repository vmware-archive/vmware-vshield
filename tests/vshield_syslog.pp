# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

vshield_syslog { $vshield['server']:
  server_info => '192.168.232.10:514',
  transport   => Transport['vshield'],
}
