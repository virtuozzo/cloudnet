require 'rails_helper'

describe ApplicationHelper do
  describe 'navigation link method' do
    before (:each) { controller.params = { controller: 'test' } }

    it 'should have the correct link and text' do
      response = helper.navigation_link 'test', 'Test', root_path
      expect(response).to have_link 'Test', href: root_path
    end

    it 'should have an active tag only if controller matches' do
      active = helper.navigation_link 'test', 'Test', root_path
      inactive = helper.navigation_link 'unknown', 'Unknown', root_path

      expect(active).to have_selector '.active'
      expect(inactive).to_not have_selector '.active'
    end
  end
end
