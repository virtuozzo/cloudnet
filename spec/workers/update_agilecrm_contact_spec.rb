require 'rails_helper'

describe UpdateAgilecrmContact, :vcr do

  it 'should create or update contact at AgileCRM' do
    user_tasks = double('UserTasks')
    allow(UserTasks).to receive(:new).and_return(user_tasks)
    allow(user_tasks).to receive(:perform).and_return(true)

    user = FactoryGirl.create(:user_onapp, email: "bella@thiel.name")

    contact = AgileCRMWrapper::Contact.search_by_email(user.email)
    expect(contact).not_to eq(nil)
    expect(contact.get_property("email")).to eq(user.email)
  end

end
