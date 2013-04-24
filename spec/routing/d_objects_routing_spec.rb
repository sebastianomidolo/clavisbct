require "spec_helper"

describe DObjectsController do
  describe "routing" do

    it "routes to #index" do
      get("/d_objects").should route_to("d_objects#index")
    end

    it "routes to #new" do
      get("/d_objects/new").should route_to("d_objects#new")
    end

    it "routes to #show" do
      get("/d_objects/1").should route_to("d_objects#show", :id => "1")
    end

    it "routes to #edit" do
      get("/d_objects/1/edit").should route_to("d_objects#edit", :id => "1")
    end

    it "routes to #create" do
      post("/d_objects").should route_to("d_objects#create")
    end

    it "routes to #update" do
      put("/d_objects/1").should route_to("d_objects#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/d_objects/1").should route_to("d_objects#destroy", :id => "1")
    end

  end
end
