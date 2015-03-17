class HostnameValidator < ActiveModel::Validator
  def validate(record)
    record.errors[:hostname] << 'is invalid' unless hostname_valid?(record)
  end

  private

  def hostname_valid?(record)
    if record.hostname.blank?
      record.errors[:hostname] << 'can not be blank'
      return false
    end

    # /^[a-zA-Z0-9\-\.]*$/ simple validation regexp
    return false if record.hostname.length > 255 || (/\A#{URI::REGEXP::PATTERN::HOST}\Z/ =~ record.hostname).nil?
    return false if record.hostname.start_with?('-') || record.hostname.end_with?('-')

    record.hostname.split('.').each do |str|
      if str.length == 0 || str.length > 64
        return false
      end
    end if record.hostname.include?('.')

    true
  end
end
