require 'rails_helper'

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

RSpec.describe BioIconograficoTopicsController, :type => :controller do

  # This should return the minimal set of attributes required to create a valid
  # BioIconograficoTopic. As you add validations to BioIconograficoTopic, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BioIconograficoTopicsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all bio_iconografico_topics as @bio_iconografico_topics" do
      bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:bio_iconografico_topics)).to eq([bio_iconografico_topic])
    end
  end

  describe "GET #show" do
    it "assigns the requested bio_iconografico_topic as @bio_iconografico_topic" do
      bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
      get :show, {:id => bio_iconografico_topic.to_param}, valid_session
      expect(assigns(:bio_iconografico_topic)).to eq(bio_iconografico_topic)
    end
  end

  describe "GET #new" do
    it "assigns a new bio_iconografico_topic as @bio_iconografico_topic" do
      get :new, {}, valid_session
      expect(assigns(:bio_iconografico_topic)).to be_a_new(BioIconograficoTopic)
    end
  end

  describe "GET #edit" do
    it "assigns the requested bio_iconografico_topic as @bio_iconografico_topic" do
      bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
      get :edit, {:id => bio_iconografico_topic.to_param}, valid_session
      expect(assigns(:bio_iconografico_topic)).to eq(bio_iconografico_topic)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new BioIconograficoTopic" do
        expect {
          post :create, {:bio_iconografico_topic => valid_attributes}, valid_session
        }.to change(BioIconograficoTopic, :count).by(1)
      end

      it "assigns a newly created bio_iconografico_topic as @bio_iconografico_topic" do
        post :create, {:bio_iconografico_topic => valid_attributes}, valid_session
        expect(assigns(:bio_iconografico_topic)).to be_a(BioIconograficoTopic)
        expect(assigns(:bio_iconografico_topic)).to be_persisted
      end

      it "redirects to the created bio_iconografico_topic" do
        post :create, {:bio_iconografico_topic => valid_attributes}, valid_session
        expect(response).to redirect_to(BioIconograficoTopic.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved bio_iconografico_topic as @bio_iconografico_topic" do
        post :create, {:bio_iconografico_topic => invalid_attributes}, valid_session
        expect(assigns(:bio_iconografico_topic)).to be_a_new(BioIconograficoTopic)
      end

      it "re-renders the 'new' template" do
        post :create, {:bio_iconografico_topic => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested bio_iconografico_topic" do
        bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
        put :update, {:id => bio_iconografico_topic.to_param, :bio_iconografico_topic => new_attributes}, valid_session
        bio_iconografico_topic.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested bio_iconografico_topic as @bio_iconografico_topic" do
        bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
        put :update, {:id => bio_iconografico_topic.to_param, :bio_iconografico_topic => valid_attributes}, valid_session
        expect(assigns(:bio_iconografico_topic)).to eq(bio_iconografico_topic)
      end

      it "redirects to the bio_iconografico_topic" do
        bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
        put :update, {:id => bio_iconografico_topic.to_param, :bio_iconografico_topic => valid_attributes}, valid_session
        expect(response).to redirect_to(bio_iconografico_topic)
      end
    end

    context "with invalid params" do
      it "assigns the bio_iconografico_topic as @bio_iconografico_topic" do
        bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
        put :update, {:id => bio_iconografico_topic.to_param, :bio_iconografico_topic => invalid_attributes}, valid_session
        expect(assigns(:bio_iconografico_topic)).to eq(bio_iconografico_topic)
      end

      it "re-renders the 'edit' template" do
        bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
        put :update, {:id => bio_iconografico_topic.to_param, :bio_iconografico_topic => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested bio_iconografico_topic" do
      bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
      expect {
        delete :destroy, {:id => bio_iconografico_topic.to_param}, valid_session
      }.to change(BioIconograficoTopic, :count).by(-1)
    end

    it "redirects to the bio_iconografico_topics list" do
      bio_iconografico_topic = BioIconograficoTopic.create! valid_attributes
      delete :destroy, {:id => bio_iconografico_topic.to_param}, valid_session
      expect(response).to redirect_to(bio_iconografico_topics_url)
    end
  end

end