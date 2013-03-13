require "spec_helper"

describe TalkingBooksController do
  describe "routing" do

    it "routes to #index" do
      get("/talking_books").should route_to("talking_books#index")
    end

    it "routes to #new" do
      get("/talking_books/new").should route_to("talking_books#new")
    end

    it "routes to #show" do
      get("/talking_books/1").should route_to("talking_books#show", :id => "1")
    end

    it "routes to #edit" do
      get("/talking_books/1/edit").should route_to("talking_books#edit", :id => "1")
    end

    it "routes to #create" do
      post("/talking_books").should route_to("talking_books#create")
    end

    it "routes to #update" do
      put("/talking_books/1").should route_to("talking_books#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/talking_books/1").should route_to("talking_books#destroy", :id => "1")
    end

  end
end
