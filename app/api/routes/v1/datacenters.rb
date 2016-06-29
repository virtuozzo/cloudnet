module Routes::V1
  # /datacenters
  class Datacenters < Grape::API
    version :v1, using: :accept_version_header
    resource :datacenters do
      before do
        authenticate!
      end
      
      desc 'List all datacenters' do
        detail 'together with an array of templates available'
        failure [[401, 'Unauthorized']]
      end
      get do
        present Location.all, with: DatacentersRepresenter
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
          begin
            present Location.find(params[:id]), with: DatacenterRepresenter
          rescue ActiveRecord::RecordNotFound
            error! "Not Found", 404
          end
        end
      end
    end
  end
end
