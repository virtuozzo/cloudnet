class UptimeTasks < BaseTasks

  def perform(action, *args)
    run_task(action, *args)
  end

  def run_task(action, *args)
    return false if no_pingdom_credentials?
    super
  end

  private

  def update_all_servers
    return [] unless good_pingdom_response?
    # Refresh server uptime data in separate processes.
    # TODO: add "Req-Limit-Short", "Req-Limit-Long" analysis
    servers.each { |server| UptimeUpdateServers.perform_async(server["id"]) }
  end

  def update_server(pingdom_id, location_id, raw_data = nil, days = 30)
    return [] if pingdom_id.nil? or location_id.nil?

    raw_data ||= performance_data(pingdom_id, days)
    perf = server_performance(raw_data, location_id)
    perf.each { |d| Uptime.create_or_update(d) }
  end

  def update_servers(pingdom_id, days = 30)
    location = Location.where(pingdom_id: pingdom_id)
    return false if location.empty?

    raw_data = performance_data(pingdom_id, days)
    location.each { |loc| update_server(pingdom_id, loc.id, raw_data, days) }
  end

  def pingdom_servers
    return [["pingdom connection error", -1]] unless good_pingdom_response?
    servers.map {|server| [server["name"], "#{server["id"]}:#{server["name"]}"]}
  end

  def servers
    @servers ||= checks.body["checks"]
  end

  def good_pingdom_response?
    checks.try(:status) == 200
  end

  #getting all servers being checked in Pingdom
  def checks
    @checks ||= connection && connection.get('checks')
  rescue Faraday::ConnectionFailed
    nil
  end

  def server_performance(raw_data, location_id)
    return [] unless raw_data.status == 200

    days_data(raw_data).map do |data|
      ::HashWithIndifferentAccess.new(data.merge(location_id: location_id))
    end
  end

  def days_data(raw_data)
    extracted = raw_data.body["summary"]["days"].dup
    extracted.pop
    extracted
  end

  def performance_data(pingdom_id, days = 30)
    connection && connection.get("summary.performance/#{pingdom_id}", performance_args(days))
  end

  def performance_args(days)
    {
      includeuptime: true,
      resolution: :day,
      from: days.days.ago.midnight.to_i
    }
  end

  def connection
    return false if no_pingdom_credentials?
    @connection ||= Faraday.new(:url => "https://api/pingdom.com/api/2.0/", ssl: {verify: false}) do |builder|
      builder.url_prefix = "https://api.pingdom.com/api/2.0"
      builder.use Faraday::Response::Logger, Rails.logger
      builder.basic_auth KEYS[:pingdom][:user], KEYS[:pingdom][:pass]
      builder.headers["App-Key"] = KEYS[:pingdom][:api_key]
      builder.response :json, content_type: /\bjson$/
      builder.adapter Faraday.default_adapter
    end
  end

  def no_pingdom_credentials?
    !KEYS[:pingdom][:user] ||
    !KEYS[:pingdom][:pass] ||
    !KEYS[:pingdom][:api_key]
  end

  def allowable_methods
    [
      :update_all_servers,
      :update_server,
      :update_servers,
      :pingdom_servers
    ] + super
  end
end