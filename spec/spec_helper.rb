require 'rspec/autorun'

RSpec.configure do |config|
  config.order = "random"
end

def relative_to_spec name
  File.join(File.dirname(File.absolute_path(__FILE__)), name)
end

# vim: set sw=2 et cc=80:
