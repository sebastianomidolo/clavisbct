require "rails_helper"

RSpec.describe BctLettersController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/bct_letters").to route_to("bct_letters#index")
    end

    it "routes to #new" do
      expect(:get => "/bct_letters/new").to route_to("bct_letters#new")
    end

    it "routes to #show" do
      expect(:get => "/bct_letters/1").to route_to("bct_letters#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/bct_letters/1/edit").to route_to("bct_letters#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/bct_letters").to route_to("bct_letters#create")
    end

    it "routes to #update" do
      expect(:put => "/bct_letters/1").to route_to("bct_letters#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/bct_letters/1").to route_to("bct_letters#destroy", :id => "1")
    end

  end
end
