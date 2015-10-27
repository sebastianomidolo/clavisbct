class BioIconograficoTopicsController < ApplicationController
  before_filter :set_bio_iconografico_topic, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @bio_iconografico_topics = BioIconograficoTopic.all
    respond_with(@bio_iconografico_topics)
  end

  def show
    respond_with(@bio_iconografico_topic)
  end

  def new
    @bio_iconografico_topic = BioIconograficoTopic.new
    respond_with(@bio_iconografico_topic)
  end

  def edit
  end

  def create
    @bio_iconografico_topic = BioIconograficoTopic.new(params[:bio_iconografico_topic])
    @bio_iconografico_topic.save
    respond_with(@bio_iconografico_topic)
  end

  def update
    @bio_iconografico_topic.update_attributes(params[:bio_iconografico_topic])
    respond_with(@bio_iconografico_topic)
  end

  def destroy
    @bio_iconografico_topic.destroy
    respond_with(@bio_iconografico_topic)
  end

  private
    def set_bio_iconografico_topic
      @bio_iconografico_topic = BioIconograficoTopic.find(params[:id])
    end
end
