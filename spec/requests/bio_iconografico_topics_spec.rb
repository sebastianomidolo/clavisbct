require 'rails_helper'

RSpec.describe "BioIconograficoTopics", :type => :request do
  describe "GET /bio_iconografico_topics" do
    it "works! (now write some real specs)" do
      get bio_iconografico_topics_path
      expect(response).to have_http_status(200)
    end
  end
end
