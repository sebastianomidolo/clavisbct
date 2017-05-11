class BioIconograficoTopicsController < ApplicationController
  layout 'bio_iconografico'
  load_and_authorize_resource

  before_filter :set_bio_iconografico_topic, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:edit,:update,:destroy]

  respond_to :html

  def index
    params[:namespace] = 'bioico' if params[:namespace].blank?

    if params[:lettera].blank?
      @show_searchbox = true
      if params[:bio_iconografico_topic].blank?
        @bio_iconografico_topic=BioIconograficoTopic.new
        @bio_iconografico_topic.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
      else
        @bio_iconografico_topic=BioIconograficoTopic.new(params[:bio_iconografico_topic])
      end
    end
    @bio_iconografico_topics=BioIconograficoTopic.list(params,@bio_iconografico_topic)
    respond_with(@bio_iconografico_topics)
  end

  def show
    params[:namespace] = 'bioico' if params[:namespace].blank?
    respond_with(@bio_iconografico_topic)
  end

  def new
    @bio_iconografico_topic = BioIconograficoTopic.new
    respond_with(@bio_iconografico_topic)
  end

  def edit
    params[:namespace] = 'bioico' if params[:namespace].blank?
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
