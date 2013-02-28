# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_loadbalancer_vip).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield load balancer vip'

  def sub_pool_id
    pool = @cur_pools.find{|x| x['name'] == resource[:pool]} if resource[:pool]

    raise Puppet::Error, "pool: #{resource[:pool]} not found, vip: #{resource[:name]} will not be created/updated" if not pool
    pool['id']
  end

  def exists?
    # grab the pools to be used later for substituting pool_ids
    @cur_pools = ensure_array( nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/pools"), [ 'loadBalancer', 'pool' ]) )

    results = ensure_array( nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/virtualservers"), [ 'loadBalancer', 'virtualServer' ]) )

    # A single result is a hash, while multiple results is an array.
    @lb_vip = results.find {|vip| vip['name'] == resource[:name] }

    # populate source,destination and service with [] entries if they are nil
    populate_properties
    @lb_vip
  end

  def populate_properties
    if @lb_vip
      [ 'applicationProfile' ].each do |prop|
          @lb_vip[prop] = ensure_array(@lb_vip[prop])
      end
      @lb_vip['pool'] = Hash.new if not @lb_vip['pool']
    end
  end

  def replace_properties
    @lb_vip['applicationProfile'] = resource[:application_profile] if resource[:application_profile]
    @lb_vip['ipAddress']          = resource[:ip_address]          if resource[:ip_address]
    @lb_vip['pool']['id']         = sub_pool_id                    if resource[:pool]
  end

  def create
    @lb_vip = {}
    populate_properties
    replace_properties

    @lb_vip['name']       = resource[:name]
    data                  = {}
    data[:virtualServer ] = @lb_vip.reject{|k,v| v.nil? }
    post("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/virtualservers", data )
  end

  def destroy
    Puppet.notice("This feature is not implemented")
  end

  def ip_address
    @lb_vip['ipAddress']
  end

  def ip_address=(ip_address=resource[:ip_address])
    @pending_changes = true
  end

  def application_profile
    @lb_vip['applicationProfile']
  end

  def application_profile=(application_profile=resource[:application_profile])
    @pending_changes = true
  end

  def pool
    pool = @cur_pools.find{|x| x['objectId'] = @lb_vip['pool']}
    pool['name'] if pool and pool['name'] 
  end

  def pool=(pool=resource[:pool])
    @pending_changes = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "Loadbalancer vip #{resource[:name]} was not found" unless @lb_vip
      replace_properties
      
      data                  = {}
      data[:virtualServer ] = @lb_vip.reject{|k,v| v.nil? }

      Puppet.debug("Updating lb_vip: #{resource[:name]}")
      put("api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/virtualservers/#{@lb_vip['id']}", data )
    end
  end
end
