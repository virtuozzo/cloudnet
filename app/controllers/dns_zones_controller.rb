class DnsZonesController < ApplicationController
  before_action :set_domain, only: [:show, :destroy, :create_record, :edit_record, :destroy_record]

  def index
    @domains = current_user.dns_zones.order(id: :asc)
    Analytics.track(current_user, event: 'Viewed DNS Zones')
    respond_to do |format|
      format.html { @domains = @domains.page(params[:page]).per(10) }
      format.json { render json: @domains }
    end
  end

  def new
    @domain = DnsZone.new
    Analytics.track(current_user, event: 'New DNS Zone')
  end

  def show
    records = LoadDnsZoneRecords.new(@domain, current_user).process
    @records = DnsZone.process_records(records)
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#Show' })
    flash[:alert] = "Could not load DNS records for domain #{@domain.domain}. Please try again later"
    redirect_to dns_zones_path
  end

  def create
    @domain = DnsZone.new(domain_params)
    @domain.user = current_user

    respond_to do |format|
      if @domain.valid?
        begin
          created_domain = CreateDnsZone.new(@domain, current_user).process
          @domain.domain_id = created_domain['id']
          @domain.save
          log_activity :create, @domain[:domain]
          Analytics.track(current_user, event: 'Created DNS Zone', properties: { zone: @domain[:domain] })

          format.html { redirect_to @domain, notice: 'Domain was successfully added to DNS' }
          format.json { render action: 'show', status: :created, location: @domain }
        rescue Exception => e
          ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#Create' })
          flash[:alert] = 'Domain could not be added on our back end. Please try again later'
          format.html { render action: 'new' }
        end
      else
        format.html { render action: 'new' }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    DeleteDnsZone.new(@domain, current_user).process
    log_activity :destroy, @domain[:domain]
    @domain.destroy
    Analytics.track(current_user, event: 'Destroyed DNS Zone', properties: { zone: @domain[:domain] })
    redirect_to dns_zones_path, notice: 'Domain has been removed from DNS'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#Destroy' })
    flash[:alert] = 'Could not destroy domain on our back end. Please try again later'
    redirect_to @domain
  end

  def create_record
    dns_record = { dns_record: dns_record_params }

    respond_to do |format|
      begin
        CreateDnsRecord.new(@domain, dns_record, current_user).process
        log_activity :create_record, @domain[:domain]
        format.json { render json: { status: 200 } }
      rescue Faraday::Error::ClientError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#CreateRecord', faraday: e.response })
        flash[:alert] = format_error_messages(e.response[:body])
        format.json { render json: e.response[:body], status: :unprocessable_entity }
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#CreateRecord' })
        flash[:alert] = format_error_messages(e.response[:body])
        format.json { render json: { errors: { 'error' => 'Server Error' } }, status: :unprocessable_entity }
      end
    end
  end

  def edit_record
    record_id  = params[:record_id]
    dns_record = { dns_record: params[:dns_record] }

    respond_to do |format|
      begin
        EditDnsRecord.new(@domain, record_id, dns_record, current_user).process
        log_activity :edit_record, @domain[:domain]
        format.json { render json: { status: 200 } }
      rescue Faraday::Error::ClientError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#EditRecord', faraday: e.response })
        flash[:alert] = format_error_messages(e.response[:body])
        format.json { render json: e.response[:body], status: :unprocessable_entity }
      end
    end
  end

  def destroy_record
    record_id  = params[:record_id]

    respond_to do |format|
      begin
        DeleteDnsRecord.new(@domain, record_id, current_user).process
        log_activity :destroy_record, @domain[:domain]
        format.html { redirect_to dns_zone_path(@domain), notice: 'DNS Record was successfully deleted' }
      rescue Faraday::Error::ClientError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'DnsZones#DestroyRecord', faraday: e.response })
        flash[:alert] = format_error_messages(e.response[:body])
        format.html { redirect_to dns_zone_path(@domain) }
      end
    end
  end

  private

  def set_domain
    @domain = current_user.dns_zones.find(params[:id])
  end

  def domain_params
    params.require(:dns_zone).permit(:domain, :autopopulate)
  end

  def dns_record_params
    case params[:type]
    when 'ns'
      params.permit(:type, :hostname, :ttl, :name)
    when 'a', 'aaaa'
      params.permit(:type, :ip, :ttl, :name)
    when 'cname'
      params.permit(:type, :hostname, :name, :ttl)
    when 'mx'
      params.permit(:type, :priority, :name, :hostname, :ttl)
    when 'txt'
      params.permit(:type, :name, :txt, :ttl)
    when 'srv'
      params.permit(:type, :priority, :weight, :port, :hostname, :ttl)
    end
  end

  def log_activity(activity, domain)
    @domain.create_activity activity, owner: current_user, params: { ip: ip, domain: domain, admin: real_admin_id }
  end
end
