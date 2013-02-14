# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_loadbalancer_pool).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield load balancer pools'

  def exists?
    results = ensure_array(nested_value(get("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/pools"), [ 'loadBalancer', 'pool' ]))

    # A single result is a hash, while multiple results is an array.
    @lb_pool = results.find {|pool| pool['name'] == resource[:name] }

    # populate source,destination and service with [] entries if they are nil
    populate_properties
    @lb_pool
  end

  def populate_properties
    if @lb_pool
      [ 'servicePort', 'member' ].each do |prop|
          @lb_pool[prop] = ensure_array(@lb_pool[prop])
      end
    end
  end

  def replace_properties
    @lb_pool['servicePort'] = resource[:service_port] if resource[:service_port]
    @lb_pool['member']      = resource[:member]       if resource[:member]
  end

  def create
    @lb_pool = {}
    populate_properties
    replace_properties

    @lb_pool['name']   = resource[:name]
    data               = {}
    data[:pool ]       = @lb_pool.reject{|k,v| v.nil? }
    post("/api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/pools", data )
  end

  def destroy
    Puppet.notice("This feature is not implemented")
  end

  def service_port
    @lb_pool['servicePort'] = @lb_pool['servicePort'].sort {|a, b| a['protocol'] <=> b['protocol']}
  end

  def service_port=(service_port=resource[:service_port])
    @pending_changes = true
  end

  def member
    @lb_pool['member'] = @lb_pool['member'].sort {|a, b| a['ipAddress'] <=> b['ipAddress']}
  end

  def member=(member=resource[:member])
    @pending_changes = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "loadbalancer pool #{resource[:name]} was not found" unless @lb_pool
      replace_properties
      data            = {}
      data[:pool ]    = @lb_pool.reject{|k,v| v.nil? }
      put("api/3.0/edges/#{vshield_edge_moref}/loadbalancer/config/pools/#{@lb_pool['id']}", data )
    end
  end
end
