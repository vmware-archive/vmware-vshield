require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

# TODO:
# Somethings foobar with rspec-puppet or spec_helper since the following code does not set the right modulepath:
# https://github.com/puppetlabs/puppetlabs_spec_helper/blob/master/lib/puppetlabs_spec_helper/module_spec_helper.rb#L21-L24
Puppet[:modulepath] = './spec/fixtures/modules'
