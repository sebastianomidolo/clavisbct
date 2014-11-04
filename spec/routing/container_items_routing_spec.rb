require "rails_helper"

RSpec.describe ContainerItemsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/container_items").to route_to("container_items#index")
    end

    it "routes to #new" do
      expect(:get => "/container_items/new").to route_to("container_items#new")
    end

    it "routes to #show" do
      expect(:get => "/container_items/1").to route_to("container_items#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/container_items/1/edit").to route_to("container_items#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/container_items").to route_to("container_items#create")
    end

    it "routes to #update" do
      expect(:put => "/container_items/1").to route_to("container_items#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/container_items/1").to route_to("container_items#destroy", :id => "1")
    end

  end
end
