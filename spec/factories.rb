FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password 'sekret123'
    full_name { Faker::Name.name }
    phone_number { Faker::Base.numerify('919400######') }
    phone_verified_at Time.now
    association :account, factory: :account

    factory :active_user do
      status :active
      confirmed_at Time.now
    end

    factory :admin do
      admin true
    end

    factory :user_onapp do
      status :active
      confirmed_at Time.now
      onapp_user 'user_onapp_test'
      onapp_password 'abcdef123456'

      trait :with_wallet do
        after(:build) do |user|
          create(:payment_receipt, account: user.account)
        end
      end
    end

    # The presence of user.account.gateway_id prevents the callback that makes a Stripe account for
    # the user
    factory :user_without_stripe do
      account nil
    end
  end

  factory :account do
    gateway_id 'cn_abc123456'
    trait :with_user do
      after(:create) do |account|
        create(:user_onapp, account: account) if account.user.nil?
      end
    end
  end

  factory :region do
    name 'Europe'
    description 'GB FR PO ES'
  end

  # This isn't a real location. But hv_group_id is very likely to be, if Onapp is properly set up
  factory :location do
    transient do
      region_name 'Europe'
    end
    latitude '-51.43423423'
    longitude '60.323233423'
    provider 'Dediserve'
    country 'GB'
    city 'London'
    region do
      Region.find_by(name: region_name) || create(:region, name: region_name)
    end
    hv_group_id '30'
    hidden false
    photo_ids '123456,789012'
    price_cpu 50
    price_disk 60
    price_bw 100
    price_memory 100
    hv_group_version '4.3.0'
    after(:build) do |location|
      3.times {|i| create("pack#{i}".to_sym, location: location) }
    end
  end

  factory :package do
    memory 512
    cpus 1
    disk_size 20
    ip_addresses 1
    location
    factory :pack0
    factory :pack1 do
      memory 1024
      cpus 2
    end
    factory :pack2 do
      disk_size 50
      cpus 3
    end
  end

  factory :template do
    identifier 5
    os_type 'linux'
    os_distro 'ubuntu'
    onapp_os_distro 'ubuntu'
    name 'Ubuntu 12.04 x64'
    association :location, factory: :location
    hidden false
    
    factory :windows_template do
      os_type 'windows'
      os_distro 'windows-2012'
      onapp_os_distro 'windows'
      name 'Windows 2012 x64'
    end
    
    factory :freebsd_template do
      os_type 'freebsd'
      os_distro 'freebsd'
      onapp_os_distro 'freebsd'
      name 'FreeBSD 10.0 x64'
    end
  end

  factory :server do
    identifier 'w909klk7ft4kp3'
    name 'My Server'
    hostname 'server.com'
    state :building
    memory 512
    cpus 1
    disk_size 20
    association :user, factory: :user_onapp
    association :template, factory: :template

    after(:build) { |s| s.update location: s.template.location }

    after(:build) do |server|
      create_list(:server_ip_address, 1, server: server)
    end

    trait :payg do
      after(:build) do |s|
        s.payment_type = :payg
        10.times {|i| create(:server_hourly_transaction, server: s, account: s.user.account) }
      end
    end
  end

  factory :server_hourly_transaction do
    association :server, factory: :server
    association :account, factory: :account
  end

  factory :server_wizard do
    name 'My Server'
    hostname 'server.com'
    memory 1024
    cpus 2
    disk_size 20
    association :user, factory: :user_onapp
    association :location, factory: :location

    after(:build) do |s|
      s.template = create(:template, location: s.location)
    end
    
    trait :with_windows_template do
      after(:build) do |s|
        s.template = create(:windows_template, location: s.location)
      end
    end
    
    trait :with_freebsd_template do
      after(:build) do |s|
        s.template = create(:freebsd_template, location: s.location)
      end
    end

    trait :with_wallet do
      after(:build) do |s|
        create(:payment_receipt, account: s.user.account)
      end
    end
  end

  factory :server_usage do
    usage_type :cpu
    usages '[{"cpu_time":1,"created_at":"2014-05-05T12:01:08Z"},{"cpu_time":0,"created_at":"2014-05-05T13:01:16Z"},{"cpu_time":0,"created_at":"2014-05-05T14:01:03Z"}]'
    association :server, factory: :server

    factory :network_server_usage do
      usage_type :network
      usages '[{"created_at":"2016-02-16T13:01:49Z","data_received":1058,"data_sent":364},{"created_at":"2016-02-17T00:59:46Z","data_received":1511,"data_sent":1664},{"created_at":"2016-02-17T01:00:54Z","data_received":11432,"data_sent":6348},{"created_at":"2016-02-19T16:01:46Z","data_received":163491,"data_sent":253359},{"created_at":"2016-03-01T17:01:49Z","data_received":853430,"data_sent":634344}]'
    end
  end

  factory :server_event do
    action 'create_virtual_server'
    status 'completed'
    association :server, factory: :server
  end

  factory :server_backup do
    backup_id 1
    built true
    identifier 'abc123'
    backup_created Date.today
    association :server, factory: :server
  end

  factory :ticket do
    subject 'My fantastic ticket'
    body 'I would like to add some more resources to my cloud'
    association :user, factory: :user
    association :server, factory: :server
  end

  factory :ticket_reply do |_n|
    body 'Some comment about the ticket by someone'
    sender 'John Smith'
    association :ticket, factory: :ticket
  end

  factory :dns_zone do
    domain 'testererw.com'
    association :user, factory: :user_onapp
    autopopulate true
    domain_id 64
  end

  factory :invoice do
    association :account, factory: [:account, :with_user]
  end

  factory :invoice_item do
    association :invoice, factory: :invoice
  end

  factory :credit_note do
    association :account, factory: [:account, :with_user]
    after(:build) do |credit_note|
      credit_note.credit_note_items = build_list(:credit_note_item, 2, credit_note: credit_note) if credit_note.credit_note_items.empty?
    end
  end

  factory :credit_note_item do
    association :credit_note, factory: :credit_note
  end

  factory :billing_card do
    bin '424242'
    ip_address '192.168.1.1'
    user_agent 'Mozilla/6.0'
    address1 '91 Brick Lane'
    city 'London'
    country 'GB'
    region 'Essex'
    postal 'E1 6QL'
    expiry_month '06'
    expiry_year '17'
    last4 '1234'
    cardholder 'Mr John Smith'
    association :account, factory: [:account, :with_user]
    processor_token 'abcd-1234567'
    fraud_verified false
  end

  factory :coupon do
    coupon_code 'ABC123'
    duration_months 6
    percentage 20
    active true
    expiry_date {Time.zone.now + 3.months}
  end

  factory :charge do
    amount 10_000
    association :invoice, factory: :invoice
    after(:build) do |charge|
      unless charge.source
        charge.source_type = 'PaymentReceipt'
        charge.source_id = create(:payment_receipt).id
      end
    end
  end

  factory :payment_receipt do
    net_cost 200000_000
    association :account, factory: [:account, :with_user]
    pay_source :paypal
  end

  factory :uptime do
    avgresponse 108
    downtime 100
    starttime 1435014000
    unmonitored 0
    uptime 86300
    association :location, factory: :location
  end

  factory :index do
    index_cpu 235
    index_iops 187
    index_bandwidth 453
    association :location, factory: :location
  end

  factory :server_ip_address do
    address '123.456.789.1'
    identifier 'xyz987'
    primary true
    association :server, factory: :server
  end

  factory :key do
    title 'joeys-macbook-pro'
    key 'ssh-rsa abc1234== joe@joeys-macbook-pro'
    association :user, factory: :user_onapp
  end

  factory :api_key do
    title 'cloudnet-control-panel'
    association :user, factory: :user_onapp
  end

  factory :user_server_count do
  end

  factory :build_checker_datum, class: BuildChecker::Data::BuildCheckerDatum do
    template
    start_after { Time.now + rand(1..10).hour }
    after(:build) do |bcd|
      bcd.location_id = bcd.template.location.id
    end
  end

  factory :tag do
    sequence(:label) { |n| "tag label #{n}"}
  end
end
