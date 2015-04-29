class ConfigHelper
  def self.load_yml_file(file)
    yaml_file = YAML.load(ERB.new(File.read("#{Rails.root}/#{file}")).result)[Rails.env]
    HashWithIndifferentAccess.new(yaml_file).deep_symbolize_keys
  end
end

ONAPP_CP  = ConfigHelper.load_yml_file('config/configurations/onapp_cp.yml')
HELPDESK  = ConfigHelper.load_yml_file('config/configurations/helpdesk.yml')
PAYMENTS  = ConfigHelper.load_yml_file('config/configurations/payments.yml')
LOGGING   = ConfigHelper.load_yml_file('config/configurations/logging.yml')
KEYS      = ConfigHelper.load_yml_file('config/configurations/keys.yml')

if ONAPP_CP[:uri]  # Sometimes Rails is loaded with initialisation, eg asset compilation
  fail "Onapp API must connect over SSL" unless URI.parse(ONAPP_CP[:uri]).scheme == 'https'
end
