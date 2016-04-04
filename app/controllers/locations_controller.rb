class LocationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    location = Location.find(params[:id])
    render partial: 'location.json', formats: [:json], locals: { location: location }
  end
  
  def templates
    templates = Location.find(params[:id]).templates.where(hidden: false).where.not(os_distro: 'docker').group_by { |t| "#{t.os_type}-#{t.os_distro}" }
    render partial: 'templates.json', formats: [:json], locals: { templates: templates }
  end
  
  def provisioner_templates
    provisioner_templates = Location.find(params[:id]).provisioner_templates.group_by { |t| "#{t.os_type}-#{t.os_distro}" }
    render partial: 'templates.json', formats: [:json], locals: { templates: provisioner_templates }
  end
  
  def packages
    @packages = Location.find(params[:id]).packages
    render partial: 'servers/packages'
  end
  
end
