require 'rails_helper'

feature 'Tickets' do
  before(:each) { authenticate_user }
  let (:ticket) { FactoryGirl.create(:ticket, user: @user) }

  scenario 'user should be able to see a list of tickets' do
    ticket.save!
    visit tickets_path
    expect(page).to have_link ticket.subject
  end

  scenario 'user should see a new ticket link' do
    visit tickets_path
    expect(page).to have_link 'New Ticket', href: new_ticket_path
  end

  scenario 'user should be able to create a ticket' do
    allow_any_instance_of(Zendesk).to receive(:new_ticket).and_return(25)

    visit new_ticket_path
    fill_in 'Subject', with: 'My terrible issue'
    fill_in 'editor', with: 'Some description of my terrible issue'
    click_button 'Submit Ticket'

    expect(current_path).to eq(ticket_path(Ticket.last.id))
    expect(page).to have_content('My terrible issue')
    expect(page).to have_content('Some description of my terrible issue')
    expect(page).to have_content('Server: No Server Selected')
    expect(page).to have_content('Department: General')
  end

  scenario 'user should be able to create a ticket with some more details' do
    server = FactoryGirl.create(:server, user: @user)
    allow_any_instance_of(Zendesk).to receive(:new_ticket).and_return(25)

    visit new_ticket_path
    fill_in 'Subject', with: 'My terrible issue'
    fill_in 'editor', with: 'Some description of my terrible issue'
    select 'Billing Issue', from: 'Department'
    select "#{server.name_with_ip}", from: 'ticket_server_id'
    click_button 'Submit Ticket'

    expect(page).to have_content('My terrible issue')
    expect(page).to have_content('Some description of my terrible issue')
    expect(page).to have_content("Server: #{server.name}")
    expect(page).to have_content('Department: Billing')
  end

  scenario 'user should be able to add reply to ticket' do
    allow_any_instance_of(Zendesk).to receive(:reply_ticket).and_return(true)

    visit ticket_path(ticket.id)
    fill_in 'editor', with: 'Some more information of my terrible issue'
    click_button 'Add Reply'

    expect(current_path).to eq(ticket_path(Ticket.last.id))
    expect(page).to have_content('Some more information of my terrible issue')
  end

  context 'ticket is closed' do
    scenario 'user should be able to close a ticket' do
      allow_any_instance_of(Zendesk).to receive(:close_ticket).and_return(true)

      visit ticket_path(ticket.id)
      click_button 'Close Ticket'

      expect(page).to have_content('Closed')
    end

    scenario 'user should not be able to close a ticket if it is closed already' do
      ticket.update(status: :solved)
      visit ticket_path(ticket.id)
      expect(page).to_not have_button('Close Ticket')
    end

    scenario 'user should not be able to add a reply' do
      ticket.update(status: :solved)
      visit ticket_path(ticket.id)
      expect(page).to_not have_content('Add Reply')
      expect(page).to_not have_button('Add Reply')
    end
  end
end
