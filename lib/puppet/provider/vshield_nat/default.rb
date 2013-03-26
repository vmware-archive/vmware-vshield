require 'pathname'
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')


Puppet::Type.type(:vshield_nat).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield nat rules '

  def edge_nat
    @edge_nat ||= begin
      nat_url   = "/api/3.0/edges/#{vshield_edge_moref}/nat/config"
      results   = ensure_array( nested_value(get("#{nat_url}"), ['nat', 'natRules', 'natRule' ]) )
      orig_addr = resource[:original_address]
      results.find {|x| x['originalAddress'] == orig_addr} 
    end
  end

  Puppet::Type.type(:vshield_nat).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method(prop) do
      v = edge_nat[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end

    define_method("#{prop}=".to_sym) do |value|
      edge_nat[camel_prop] = value
      @pending_changes = true
    end
  end

  def exists?
    edge_nat
  end

  def replace_properties
    data = {}
    data['originalAddress'] = resource[:original_address]
    Puppet::Type.type(:vshield_nat).properties.collect{|x| x.name}.reject{|x| x == :ensure}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
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

  def snat_prop_reject(data)
    ['protocol','icmpType','originalPort','translatedPort'].each do |prop|
      data.delete(prop) if data.has_key?(prop)
    end
    data
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "nat not found for #{resource[:name]}" unless edge_nat
      data    = edge_nat.update(replace_properties).reject{|k,v| v.nil?}
      
      # if dnat is changed to snat, certain properites need to be removed
      data = snat_prop_reject(data) if resource[:action] == :snat

      put_url = "api/3.0/edges/#{vshield_edge_moref}/nat/config/rules/#{edge_nat['ruleId']}"
      Puppet.debug("Updating nat for edge: #{resource[:name]}")
      put("#{put_url}", {'natRule' => data})
    end
  end
end
