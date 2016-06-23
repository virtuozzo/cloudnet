module Routes
  # /datacenters
  class Datacenters < Grape::API
    version :v1, using: :accept_version_header
    resource :datacenters do
      desc 'List all datacenters' do
        detail 'dddd'
      end
      get do
        present Location.all, with: DatacentersRepresenter
      end

      route_param :id do
        desc 'Return information about a specific datacenter'
        params do
          requires :id, type: Integer, desc: 'ID of the datacenter'
        end
        get do
          present Location.find(params[:id]), with: DatacenterRepresenter
        end
      end
    end
    
    
    desc 'Returns your public timeline.' do
      detail 'more details'
    
      failure [[401, 'Unauthorized']]
    end
    params do
      requires :user, type: Hash do
        requires :first_name, type: String
        requires :last_name, type: String
      end
    end
    get :public_timeline do
      { 'declared_params' => declared(params) }
    end
  end
end
