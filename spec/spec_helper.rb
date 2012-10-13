require 'rspec/autorun'

RSpec.configure do |config|
  config.order = 'random'
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

def relative_to_spec name
  File.join(File.dirname(File.absolute_path(__FILE__)), name)
end

# vim: set sw=2 et cc=80:
