module Routes::V1
  # /datacenters
  class Datacenters < Grape::API
    include Grape::Kaminari

    version :v1, using: :accept_version_header
    resource :datacenters do
      before do
        authenticate!
      end

      desc 'List all datacenters' do
        detail 'together with an array of templates available'
        failure [[400, 'Bad Request'], [401, 'Unauthorized']]
      end
      paginate per_page: 10, max_per_page: 20, offset: false
      get do
        present paginate(Location.where(hidden: false, budget_vps: false)), with: DatacentersRepresenter
      end

      route_param :id do
        desc 'Return information about a specific datacenter' do
          detail 'together with an array of templates available'
          failure [[400, 'Bad Request'], [401, 'Unauthorized'], [404, 'Not Found']]
        end
        params do
          requires :id, type: Integer, desc: 'ID of the datacenter'
        end
        get do
          present Location.find(params[:id]), with: DatacenterRepresenter
        end
      end
    end
  end
end
