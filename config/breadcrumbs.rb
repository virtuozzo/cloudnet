crumb :dashboard do
  link 'Dashboard', root_path
end

crumb :servers do
  link 'Servers', servers_path
end

crumb :server do |server|
  link server.name, server_path(server)
  parent :servers
end

crumb :edit_server do |server|
  server = Server.find(server)
  link 'Edit', edit_server_path(server)
  parent :server, server
end

crumb :console do |server|
  link 'Server Console', console_server_path(server)
  parent :server, server
end

crumb :backups do |server|
  link 'Server Backups', server_backups_path(server)
  parent :server, server
end

crumb :new_server do
  link 'Create Server', new_server_wizard_path
  parent :servers
end

crumb :tickets do
  link 'Tickets', tickets_path
end

crumb :ticket do |ticket|
  link "Ticket ##{ticket.reference}: #{ticket.subject}", ticket_path(ticket)
  parent :tickets
end

crumb :new_ticket do
  link 'Create Ticket', new_ticket_path
  parent :tickets
end

crumb :dns_zones do
  link 'DNS', dns_zones_path
end

crumb :dns_zone do |domain|
  link domain.domain, dns_zone_path(domain)
  parent :dns_zones
end

crumb :new_dns_zone do
  link 'Add Domain', new_dns_zone_path
  parent :dns_zones
end

crumb :edit_user do
  link 'Edit User', edit_user_registration_path
end

crumb :two_factor_auth do
  link 'Two Factor Authentication', user_otp_token_path
  parent :edit_user
end

crumb :recovery_2fa do
  link 'Recovery Codes', recovery_user_otp_token_path
  parent :two_factor_auth
end

crumb :billing do
  link 'Billing', billing_index_path
end

# crumb :projects do
#   link "Projects", projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
