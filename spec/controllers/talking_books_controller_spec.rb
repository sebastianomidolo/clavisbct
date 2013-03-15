require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe TalkingBooksController do

  # This should return the minimal set of attributes required to create a valid
  # TalkingBook. As you add validations to TalkingBook, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {  }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # TalkingBooksController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all talking_books as @talking_books" do
      talking_book = TalkingBook.create! valid_attributes
      get :index, {}, valid_session
      assigns(:talking_books).should eq([talking_book])
    end
  end

  describe "GET show" do
    it "assigns the requested talking_book as @talking_book" do
      talking_book = TalkingBook.create! valid_attributes
      get :show, {:id => talking_book.to_param}, valid_session
      assigns(:talking_book).should eq(talking_book)
    end
  end

  describe "GET new" do
    it "assigns a new talking_book as @talking_book" do
      get :new, {}, valid_session
      assigns(:talking_book).should be_a_new(TalkingBook)
    end
  end

  describe "GET edit" do
    it "assigns the requested talking_book as @talking_book" do
      talking_book = TalkingBook.create! valid_attributes
      get :edit, {:id => talking_book.to_param}, valid_session
      assigns(:talking_book).should eq(talking_book)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new TalkingBook" do
        expect {
          post :create, {:talking_book => valid_attributes}, valid_session
        }.to change(TalkingBook, :count).by(1)
      end

      it "assigns a newly created talking_book as @talking_book" do
        post :create, {:talking_book => valid_attributes}, valid_session
        assigns(:talking_book).should be_a(TalkingBook)
        assigns(:talking_book).should be_persisted
      end

      it "redirects to the created talking_book" do
        post :create, {:talking_book => valid_attributes}, valid_session
        response.should redirect_to(TalkingBook.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved talking_book as @talking_book" do
        # Trigger the behavior that occurs when invalid params are submitted
        TalkingBook.any_instance.stub(:save).and_return(false)
        post :create, {:talking_book => {  }}, valid_session
        assigns(:talking_book).should be_a_new(TalkingBook)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        TalkingBook.any_instance.stub(:save).and_return(false)
        post :create, {:talking_book => {  }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested talking_book" do
        talking_book = TalkingBook.create! valid_attributes
        # Assuming there are no other talking_books in the database, this
        # specifies that the TalkingBook created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        TalkingBook.any_instance.should_receive(:update_attributes).with({ "these" => "params" })
        put :update, {:id => talking_book.to_param, :talking_book => { "these" => "params" }}, valid_session
      end

      it "assigns the requested talking_book as @talking_book" do
        talking_book = TalkingBook.create! valid_attributes
        put :update, {:id => talking_book.to_param, :talking_book => valid_attributes}, valid_session
        assigns(:talking_book).should eq(talking_book)
      end

      it "redirects to the talking_book" do
        talking_book = TalkingBook.create! valid_attributes
        put :update, {:id => talking_book.to_param, :talking_book => valid_attributes}, valid_session
        response.should redirect_to(talking_book)
      end
    end

    describe "with invalid params" do
      it "assigns the talking_book as @talking_book" do
        talking_book = TalkingBook.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TalkingBook.any_instance.stub(:save).and_return(false)
        put :update, {:id => talking_book.to_param, :talking_book => {  }}, valid_session
        assigns(:talking_book).should eq(talking_book)
      end

      it "re-renders the 'edit' template" do
        talking_book = TalkingBook.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TalkingBook.any_instance.stub(:save).and_return(false)
        put :update, {:id => talking_book.to_param, :talking_book => {  }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested talking_book" do
      talking_book = TalkingBook.create! valid_attributes
      expect {
        delete :destroy, {:id => talking_book.to_param}, valid_session
      }.to change(TalkingBook, :count).by(-1)
    end

    it "redirects to the talking_books list" do
      talking_book = TalkingBook.create! valid_attributes
      delete :destroy, {:id => talking_book.to_param}, valid_session
      response.should redirect_to(talking_books_url)
    end
  end

end