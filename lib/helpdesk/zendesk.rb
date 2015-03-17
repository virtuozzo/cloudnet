require 'zendesk_api'
require 'logger'

# Helpdesk Class which uses the Zendesk API. In theory, you could
# rip all this out and replace with your own integration of a
# helpdesk as long as it overrides the correct methods

class Zendesk < Helpdesk::Methods
  def initialize
    @client = ZendeskAPI::Client.new do |config|
      config.url          = HELPDESK[:zendesk][:api_url]
      config.username     = HELPDESK[:zendesk][:user]
      config.token        = HELPDESK[:zendesk][:token]
      config.retry        = true
      config.logger       = Rails.logger

      # Merged with the default client options hash
      # config.client_options = { :ssl => false }
    end
  end

  def new_ticket(id, details)
    # In the details hash, the following params are set
    # subject, body, user, department, server

    params = {
      external_id: id,
      subject: details[:subject],
      comment: { body: details[:body] },
      requester: { name: details[:user].full_name, email: details[:user].email },
      group_id: department_group(details[:department]),
      custom_fields: [
        { id: HELPDESK[:zendesk][:department_key], value: details[:department] },
        { id: HELPDESK[:zendesk][:server_key], value: details[:server] }
      ]
    }

    info = ZendeskAPI::Ticket.create(@client, params)
    info.id
  end

  def get_ticket(ref)
    ticket = ZendeskAPI::Ticket.find(@client, id: ref)
    comment = ticket.comments.first

    {
      id: ticket.id,
      subject: ticket.subject,
      status: ticket.status,
      body: comment.body,
      author: comment.author.name,
      author_email: comment.author.email,
      created_at: ticket.created_at
    }
  end

  def reply_ticket(ref, body, _user)
    ticket = ZendeskAPI::Ticket.find(@client, id: ref)
    ticket.comment = { body: body, author_id: ticket.requester.id }
    ticket.save
  end

  def reopen_ticket(ref)
    ticket = ZendeskAPI::Ticket.find(@client, id: ref)
    ticket.status = :pending
    ticket.save
  end

  def close_ticket(ref)
    ticket = ZendeskAPI::Ticket.find(@client, id: ref)
    ticket.status = :closed
    ticket.save
  end

  def ticket_details(ref)
    ticket = ZendeskAPI::Ticket.find(@client, id: ref)
    return unless ticket

    comments = ticket.comments.map do |comment|
      if comment.public? && comment.via.channel.downcase != 'api'
        comment.slice(:id, :html_body, :body, :created_at).merge(author: comment.author.name, author_email: comment.author.email)
      end
    end

    ticket.slice(:id, :external_id, :subject, :status, :created_at).merge(replies: comments.compact)
  end

  def self.departments
    HELPDESK[:zendesk][:departments]
  end

  def self.config
    HELPDESK[:zendesk]
  end

  private

  def department_group(department)
    department = department.to_sym
    if self.class.departments.key?(department)
      return self.class.departments[department][:group_id]
    else
      return self.class.departments[:general][:group_id]
    end
  end
end
