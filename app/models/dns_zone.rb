class DnsZone < ActiveRecord::Base
  include PublicActivity::Common
  acts_as_paranoid

  RECORD_TYPES = %w(soa ns a aaaa cname mx txt srv)
  belongs_to :user

  validates :domain, :user, presence: true
  validates :autopopulate, inclusion: { in: [true, false] }

  attr_accessor :autopopulate

  def domain=(domain)
    domain.gsub!(/http(s)?:\/\//, '') if domain.present?
    write_attribute(:domain, domain)
  end

  def autopopulate=(value)
    @autopopulate = ActiveRecord::Type::Boolean.new.type_cast_from_database(value)
  end

  def self.process_records(records)
    records   = records['records']
    processed = {}

    DnsZone::RECORD_TYPES.each do |type|
      group = records.key?(type.upcase) ? records[type.upcase] : []
      processed[type.to_sym] = group.collect { |r| r['dns_record'].symbolize_keys }
    end

    processed
  end
end
