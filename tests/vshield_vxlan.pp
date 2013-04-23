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

vshield_vxlan_switch { "${vxlan_switch1['switch']['name']}":
  switch            => $vxlan_switch1['switch'],
  teaming           => $vxlan_switch1['teaming'],
  mtu               => $vxlan_switch1['mtu'],
  datacenter_name   => $dc1['name'],
  transport         => Transport['vshield'],
}

vshield_vxlan_map { $vxlan_map1['vlan_id']:
  switch          => $vxlan_map1['switch'],
  vlan_id         => $vxlan_map1['vlan_id'],
  datacenter_name => $dc1['name'],
  cluster_name    => $cluster1['name'],
  require         => Vshield_vxlan_switch["${vxlan_switch1[switch][name]}"],
  transport       => Transport['vshield'],
}

vshield_vxlan_segment { $vxlan_segment1['name']:
  id        => $vxlan_segment1['id'],
  name      => $vxlan_segment1['name'],
  desc      => $vxlan_segment1['desc'],
  begin     => $vxlan_segment1['begin'],
  end       => $vxlan_segment1['end'],
  require   => Vshield_vxlan_map["${vxlan_map1[vlan_id]}"],
  transport => Transport['vshield'],
}

vshield_vxlan_multicast { $vxlan_multicast1['name']:
  id        => $vxlan_multicast1['id'],
  name      => $vxlan_multicast1['name'],
  desc      => $vxlan_multicast1['desc'],
  begin     => $vxlan_multicast1['begin'],
  end       => $vxlan_multicast1['end'],
  require   => Vshield_vxlan_segment["${vxlan_segment1[name]}"],
  transport => Transport['vshield'],
}

vshield_vxlan_scope { $vxlan_scope1['name']:
  name            => $vxlan_scope1['name'],
  clusters        => $vxlan_scope1['clusters'],
  datacenter_name => $dc1['name'],
  cluster_name    => $cluster1['name'],
  require         => Vshield_vxlan_multicast["${vxlan_multicast1[name]}"],
  transport       => Transport['vshield'],
}

vshield_vxlan { $vxlan1['name']:
  name        => $vxlan1['name'],
  description => $vxlan1['description'],
  tenant_id   => $vxlan1['tenant_id'],
  require     => Vshield_vxlan_scope["${vxlan_scope1[name]}"],
  transport   => Transport['vshield'],
}

vshield_vxlan_udp { $vshield['server']:
  vxlan_udp_port  => $vxlan_udp_port,
  require         => Vshield_vxlan["${vxlan1[name]}"],
  transport       => Transport['vshield'],
}
