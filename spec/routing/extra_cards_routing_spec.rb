require "rails_helper"

RSpec.describe ExtraCardsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/extra_cards").to route_to("extra_cards#index")
    end

    it "routes to #new" do
      expect(:get => "/extra_cards/new").to route_to("extra_cards#new")
    end

    it "routes to #show" do
      expect(:get => "/extra_cards/1").to route_to("extra_cards#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/extra_cards/1/edit").to route_to("extra_cards#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/extra_cards").to route_to("extra_cards#create")
    end

    it "routes to #update" do
      expect(:put => "/extra_cards/1").to route_to("extra_cards#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/extra_cards/1").to route_to("extra_cards#destroy", :id => "1")
    end

  end
end
