require 'rails_helper'

RSpec.describe "ExtraCards", :type => :request do
  describe "GET /extra_cards" do
    it "works! (now write some real specs)" do
      get extra_cards_path
      expect(response).to have_http_status(200)
    end
  end
end
