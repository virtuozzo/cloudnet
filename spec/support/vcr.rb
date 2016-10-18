require 'vcr'

# Use the .env file to compile the list of sensitive data that should not be recorded in
# cassettes
NOT_REPLACE = %w(ONAPP_ROLE ONAPP_BILLING_PLAN_ID SIFT_USER_VALIDATE_ACTION_ID SIFT_USER_APPROVE_ACTION_ID ONAPP_API_ALLOW_INSECURE COVERAGE SMTP_SSL_VERIFY)
def sensitive_strings
  dotenv_path = "#{Rails.root}/.env"
  # It's not a big deal if there isn't a .env file when playing back cassettes, it's only when
  # recording that it would be annoying. As you'd get a lot of noise as VCR would think that *all*
  # the computer's ENV vars were confidential, eg; ENV['HOME'] etc
  unless File.exist? dotenv_path
    puts 'Warning: using ENV global instead of `.env` file to populate sensitive credentials.'
    return ENV
  end
  contents = File.read dotenv_path
  words = contents.split(/\s+/)
  # Only interested in words with an '=' in them and not in NOT_REPLACE
  words.reject! { |w| !w.include?('=') || NOT_REPLACE.any? {|n| w.include? n}}
  # Create a list of key/value pairs
  words.map! { |w| w.split('=', 2) }
  # Turn the key/value pairs into an actual hash
  Hash[words]
end

# Because some API requests prepend URIs with http://`user:pass`@domain.com then domain matching
# doesn't work. So provide a protocol-less version of URIs for matching.
def extract_domain(string)
  URI.parse(string).host
rescue
  string
end

RSpec.configure do |config|
  config.before(:example, :vcr) do
    # Run Sidekiq tests straight away without queuing on Redis
    Sidekiq::Testing.inline!
  end
  config.after(:example, :vcr) do
    Sidekiq::Testing.fake!
  end
end

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true

  # Filter out sensitive data and replace with ERB interpolation.
  # Assuming that you're using .env to store your sensitive app credentials, then you can
  # use VCR's `filter_sensitive_data` method to convert occurrences of those credentials
  # to `<%= ENV['#{key}'] %>` in your recorded VCR cassettes.
  sensitive_strings.each do |key, sensitive_string|
    # NB: intentionally not interpolating ENV[] as #{ENV[]}. We actually *want* '<%= ENV[*] %>' to
    # appear in VCR's ERB-enabled YML files
    manifestations = {
      extract_domain(sensitive_string) => "<%= extract_domain ENV['#{key}'] %>",
      CGI.escape(sensitive_string)     => "<%= CGI.escape ENV['#{key}'] %>",
      sensitive_string                 => "<%= ENV['#{key}'] %>"
    }
    manifestations.each_pair do |string, replacement|
      c.filter_sensitive_data(replacement) { string }
    end
  end

  c.default_cassette_options = { record: :new_episodes, erb: :true }

  c.ignore_hosts 'api.segment.io'
end
