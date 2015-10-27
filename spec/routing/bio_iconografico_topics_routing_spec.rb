require "rails_helper"

RSpec.describe BioIconograficoTopicsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/bio_iconografico_topics").to route_to("bio_iconografico_topics#index")
    end

    it "routes to #new" do
      expect(:get => "/bio_iconografico_topics/new").to route_to("bio_iconografico_topics#new")
    end

    it "routes to #show" do
      expect(:get => "/bio_iconografico_topics/1").to route_to("bio_iconografico_topics#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/bio_iconografico_topics/1/edit").to route_to("bio_iconografico_topics#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/bio_iconografico_topics").to route_to("bio_iconografico_topics#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/bio_iconografico_topics/1").to route_to("bio_iconografico_topics#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/bio_iconografico_topics/1").to route_to("bio_iconografico_topics#destroy", :id => "1")
    end

  end
end
