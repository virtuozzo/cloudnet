module DnsZonesHelper
  def dns_editable_record(record, key)
    content_tag :span,
                record[key],
                :class => 'dns_editable',
                'data-type' => 'text',
                'data-name' => key.to_s.downcase,
                'data-url' => "/dns_zones/#{@domain.id}/edit_record",
                'data-pk' => record[:id]
  end

  def dns_ttl_options
    options_for_select([
      ['1 Minute', '60'],
      ['15 Minutes', '900'],
      ['30 Minutes', '1800'],
      ['1 Hour', '3600'],
      ['1 Day', '86400'],
      ['3 Days', '259200'],
      ['1 Week', '604800']
    ], '900')
  end
end
