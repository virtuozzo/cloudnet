require 'rails_helper'

describe DnsZonesController do
  describe 'as a signed in user' do
    before(:each) { sign_in_onapp_user }

    describe 'going to the index page' do
      it 'should be on the dns zones index page' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('dns_zones/index')
      end

      it 'should assign @domains to display for the current user' do
        domains = FactoryGirl.create_list(:dns_zone, 5, user: @current_user)
        get :index
        expect(assigns(:domains)).to match_array(domains)
      end
    end

    describe 'going to the DNS zone create page' do
      it 'should be on the new page' do
        get :new
        expect(response).to be_success
        expect(response).to render_template('dns_zones/new')
      end

      it 'should create a new DNS zone model' do
        get :new
        expect(assigns[:domain]).to be_a(DnsZone)
      end
    end

    describe 'going to the DNS zone show page' do
      let(:domain) { FactoryGirl.create(:dns_zone, user: @current_user) }

      before :each do
        records = { 'records' => {} }
        allow_any_instance_of(LoadDnsZoneRecords).to receive(:process).and_return(records)
      end

      it 'should render the show template' do
        get :show, id: domain.id
        expect(response).to be_success
        expect(response).to render_template('dns_zones/show')
      end

      it 'should show records for the domain' do
        get :show, id: domain.id
        expect(response).to be_success
        expect(assigns(:records)).to be_present
      end
    end
  end
end
