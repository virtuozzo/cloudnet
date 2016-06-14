module Routes
  # /datacentres
  class Datacentres < Grape::API
    version :v1, using: :accept_version_header
    resource :datacentres do
      desc 'List all datacentres'
      get do
        present Location.all, with: DatacentresRepresenter
      end

      route_param :id do
        desc 'Return information about a specific datacentre'
        params do
          requires :id, type: Integer, desc: 'ID of the datacentre'
        end
        get do
          present Location.find(params[:id]), with: DatacentreRepresenter
        end
      end
    end
  end
end
