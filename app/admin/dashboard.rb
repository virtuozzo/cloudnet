ActiveAdmin.register_page 'Dashboard' do
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    columns do
      column do
        panel 'Statistics' do
          def resources
            @resources ||= Server.purchased_resources
          end
          
          table do
            tr do
              td 'Total Servers'
              td Server.count
            end
            
            tr do
              td 'Total Servers Running'
              td Server.where(state: 'on').count
            end

            tr do
              td 'Users with Servers Running'
              td Server.where(state: 'on').pluck('DISTINCT user_id').count
            end

            tr do
              td 'Servers Created This Calendar Month'
              td Server.with_deleted.created_this_month.count
            end

            tr do
              td 'Servers Destroyed This Calendar Month'
              td Server.only_deleted.deleted_this_month.count
            end

            tr do
              last_month = Time.now - 1.month
              td 'Servers Created Last Calendar Month'
              td Server.with_deleted.created_last_month.count
            end

            tr do
              last_month = Time.now - 1.month
              td 'Servers Destroyed Last Calendar Month'
              td Server.only_deleted.deleted_last_month.count
            end

            tr do
              td 'Total Users'
              td User.count
            end

            tr do
              td 'Users This Calendar Month'
              td User.created_this_month.count
            end

            tr do
              td 'Total Tickets'
              td Ticket.count
            end

            tr do
              tickets = Ticket.arel_table
              td 'Pending Tickets (Not Closed/Solved)'
              td Ticket.where.not(tickets[:status].in [:solved, :closed]).count
            end

            tr do
              td 'Tickets This Calendar Month'
              td Ticket.created_this_month.count
            end

            tr do
              td 'Cores'
              td resources[:cpu]
            end
            
            tr do
              td 'Memory [MB]'
              td  number_with_delimiter(resources[:mem])
            end
            
            tr do
              td 'Disc Space [GB]'
              td  number_with_delimiter(resources[:disc])
            end
            
            tr do 
              forecast = (Server.sum(:forecasted_rev) / Invoice::MILLICENTS_IN_DOLLAR).round(2)
              td 'Forecasted Month Revenue [USD]'
              td forecast
            end
          end
        end
      end

      column do
        panel 'Servers By Location/Provider' do
          table do
            Location.all.order('provider ASC').map do |location|
              tr do
                td link_to location.provider_label, admin_location_path(location)
                td location.servers.count
              end
            end
          end
        end
      end
    end

    columns do
      column do
        panel 'New Servers' do
          ul do
            Server.all.order('id desc').limit(5).map do |server|
              li link_to("#{server.name} (#{server.user.full_name})", admin_server_path(server))
            end
          end
        end
      end

      column do
        panel 'New Users' do
          ul do
            User.all.order('id desc').limit(5).map do |user|
              li link_to("#{user.full_name} (#{user.email})", admin_user_path(user))
            end
          end
        end
      end
    end

    columns do
      column do
        panel 'Recent Pending Tickets (Tickets Not Solved/Closed)' do
          ul do
            tickets = Ticket.arel_table
            Ticket.where.not(tickets[:status].in [:solved, :closed]).order('id desc').limit(5).map do |ticket|
              li link_to("#{ticket.subject} (#{ticket.user.full_name})", admin_ticket_path(ticket))
            end
          end
        end
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
end
