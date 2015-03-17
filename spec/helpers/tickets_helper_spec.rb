require 'rails_helper'

describe TicketsHelper do
  let (:departments) { Helpdesk.departments }

  it 'should return an array of arrays for departments for the select dropdown' do
    d = helper.form_departments
    expect(d).not_to be_empty

    first = departments.keys.first
    expect(d.first).to eq([departments[first][:name], first.to_s])
    expect(d.size).to eq(departments.keys.size)
  end
end
