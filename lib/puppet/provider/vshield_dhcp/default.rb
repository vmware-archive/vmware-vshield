# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_dhcp).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'manage vshield edge dhcp service.'
  
  def edge_dhcp
    @edge_dhcp ||= begin     
      results = nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/dhcp/config"), [ 'dhcp' ] )
      
      results['ipPools'] ||= {}
      results['staticBindings'] ||= {}
      results['logging'] ||= {}
      results['enabled'] ||= {}

      results['ipPools']['ipPool'] = ensure_array(results['ipPools']['ipPool'])
      results['staticBindings']['staticBinding'] = ensure_array(results['staticBindings']['staticBinding'])

      results
    end
  end
  
  def dhcp_pools
    edge_dhcp['ipPools']['ipPool'] 
  end
  
  def dhcp_pools=(value)
    edge_dhcp['ipPools']['ipPool'] = value
    @pending_changes = true
  end
  
  def dhcp_bindings
    edge_dhcp['staticBindings']['staticBinding']
  end
  
  def dhcp_bindings=(value)
    edge_dhcp['staticBindings']['staticBinding'] = value
    @pending_changes = true
  end
  
  def dhcp_logging
    edge_dhcp['logging']
  end
  
  def dhcp_logging=(value)
    edge_dhcp['logging'] = value
    @pending_changes = true
  end
  
  def dhcp_enabled
    edge_dhcp['enabled']
  end
  
  def dhcp_enabled=(value)
    edge_dhcp['enabled'] = value
    @pending_changes = true
  end
 
  def datacenter(name=resource[:datacenter_name])
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{name}' not found."
  end

  # will not find vms in folders  
  def virtual_machine(name)
    vm = datacenter.find_vm(name) or raise Puppet::Error, "virtual machine '#{name}' not found."
    vm._ref
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "DHCP Settings not found for: #{resource[:name]}" unless edge_dhcp
     
      # only works if hostname matches vm name 
      edge_dhcp['staticBindings']['staticBinding'].each do |staticBinding|
        staticBinding['vmId'] = virtual_machine(staticBinding['hostname'])
      end
      
      Puppet.debug("Updating DHCP settings for edge: #{resource[:name]}")
      put("api/3.0/edges/#{vshield_edge_moref}/dhcp/config", { 'dhcp' => edge_dhcp } ) 
    end
  end
end
