require 'pathname'
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')


Puppet::Type.type(:vshield_nat).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield nat rules '

  def resources
    [ 'action',
      'vnic',
      'original_address',
      'translated_address',
      'protocol',
      'translated_port',
      'original_port'
    ]
  end

  def edge_nat
    @edge_nat ||= begin
      nat_rule  = {}
      nat_url   = "/api/3.0/edges/#{vshield_edge_moref}/nat/config"
      results   = ensure_array( nested_value(get("#{nat_url}"), ['nat', 'natRules', 'natRule' ]) )
      orig_addr = resource[:original_address]
      nat_rule = results.find {|x| x['originalAddress'] == orig_addr} 
      nat_rule
    end
  end

  def exists?
    edge_nat
  end

  def replace_properties
    data     = {}
    resources.each do |property|
      if resource[:"#{property}"]
        camel_prop       = PuppetX::VMware::Util.camelize(property, :lower)
        data[camel_prop] = resource[:"#{property}"].to_s
      end
    end
    data
  end

  def create
    post_url = "api/3.0/edges/#{vshield_edge_moref}/nat/config/rules"
    post("#{post_url}", { 'natRules' => { 'natRule' => replace_properties } } )
  end

  def destroy
    delete("api/3.0/edges/#{vshield_edge_moref}/nat/config/rules/#{edge_nat['ruleId']}")
  end

  def action
    edge_nat['action']
  end

  def action=(value)
    edge_nat['action']   = value
    @pending_changes = true
  end

  def vnic
    edge_nat['vnic']
  end

  def vnic=(value)
    edge_nat['vnic']     = value
    @pending_changes = true
  end

  def original_address
    edge_nat['originalAddress']
  end

  def original_address=(value)
    edge_nat['originalAddress'] = value
    @pending_changes        = true
  end

  def translated_address
    edge_nat['translatedAddress']
  end

  def translated_address=(value)
    edge_nat['translatedAddress'] = value
    @pending_changes          = true
  end

  def protocol
    edge_nat['protocol']
  end

  def protocol=(value)
    edge_nat['protocol'] = value
    @pending_changes = true
  end

  def icmp_type
    edge_nat['icmpType']
  end

  def icmp_type=(value)
    edge_nat['icmpType'] = value
    @pending_changes = true
  end

  def enabled
    value = edge_nat['enabled']
    value = :true  if TrueClass  === value
    value = :false if FalseClass === value
    value
  end

  def enabled=(value)
    edge_nat['enabled'] = value
    @pending_changes = true
  end

  def original_port
    edge_nat['originalPort']
  end

  def original_port=(value)
    edge_nat['originalPort'] = value
    @pending_changes     = true
  end

  def translated_port
    edge_nat['translatedPort']
  end

  def translated_port=(value)
    edge_nat['translatedPort'] = value
    @pending_changes       = true
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "nat not found for #{resource[:name]}" unless edge_nat
      data    = edge_nat.update(replace_properties).reject{|k,v| v.nil?}
      put_url = "api/3.0/edges/#{vshield_edge_moref}/nat/config/rules/#{edge_nat['ruleId']}"
      Puppet.debug("Updating nat for edge: #{resource[:name]}")
      put("#{put_url}", {'natRule' => data})
    end
  end
end
