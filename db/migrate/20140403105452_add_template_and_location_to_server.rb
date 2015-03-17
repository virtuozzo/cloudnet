class AddTemplateAndLocationToServer < ActiveRecord::Migration
  class Server < ActiveRecord::Base
  end

  def change
    add_reference :servers, :location, index: true
    add_reference :servers, :template, index: true

    # Add a default location and template for each of our existing servers
    Server.reset_column_information
    location = Location.first
    template = location.templates.first if location

    reversible do |dir|
      dir.up { Server.update_all(location_id: location.id, template_id: template.id) if template }
    end
  end
end
