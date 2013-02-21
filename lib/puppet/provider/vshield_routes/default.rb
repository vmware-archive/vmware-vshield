require 'pathname'
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')


Puppet::Type.type(:vshield_routes).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield static routes'

  def get_vnic_name_by_index(vnic_index)
    if vnic_index
      @vnics.find{|x| x['index'] == vnic_index}['name']
    else
      return ''
    end
  end

  def get_vnic_index_by_name(vnic_name)
    if vnic_name
      @vnics.find{|x| x['name'] == vnic_name}['index']
    else
      return "0"
    end
  end

  def edge_routes
    @edge_routes ||= begin
      vnic_url = "api/3.0/edges/#{vshield_edge_moref}/vnics"
      @vnics = ensure_array(nested_value(get("#{vnic_url}"), [ 'vnics', 'vnic' ]) )

      results = nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/routing/config"), [ 'staticRouting' ] )
      results['defaultRoute'] ||= {}
      results['staticRoutes'] ||= {}
      
      # convert vnic index to vnic name
      # only convert vnic if we got an index in from the vsm/vse
      if results['defaultRoute']['vnic']
        results['defaultRoute']['vnic'] = get_vnic_name_by_index(results['defaultRoute']['vnic'])
      end

      results['staticRoutes']['route'] = ensure_array(results['staticRoutes']['route'])
      results['staticRoutes']['route'].each do |route|
        route['vnic'] = get_vnic_name_by_index(route['vnic'])
      end
      results
    end
  end

  def default_route
    edge_routes['defaultRoute']
  end

  def default_route=(value)
    edge_routes['defaultRoute'] = value
    @pending_changes = true
  end

  def static_routes
    edge_routes['staticRoutes']['route']
  end

  def static_routes=(value)
    edge_routes['staticRoutes']['route'] = value
    @pending_changes = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "Routes not found for #{resource[:name]}" unless edge_routes

      # convert back to vnic index and default to 1500 mtu as needed if vnic exists
      if edge_routes['defaultRoute']['vnic']
        edge_routes['defaultRoute']['vnic'] = get_vnic_index_by_name(edge_routes['defaultRoute']['vnic'])
        edge_routes['defaultRoute']['mtu'] ||= "1500"
      else
        # we need to clear the default route
        edge_routes.delete('defaultRoute')
      end

      edge_routes['staticRoutes']['route'].each do |route|
        route['vnic'] = get_vnic_index_by_name(route['vnic'])
        route['mtu'] ||= "1500"
      end

      Puppet.debug("Updating routes for edge: #{resource[:name]}")
      Puppet.debug("PUT data: #{edge_routes.inspect}")
      put("api/3.0/edges/#{vshield_edge_moref}/routing/config", {'staticRouting' => edge_routes})
    end
  end
end
