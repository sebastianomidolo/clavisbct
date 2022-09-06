# coding: utf-8
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.role?('sys_admin')
      can :manage, :all
      return
    end

    if user.role?('bio_iconografico_carica_scansioni')
      can [:read,:create,:upload,:update,:numera], BioIconograficoCard
      can :read, [BioIconograficoTopic]
    end
    if user.role?('bio_iconografico_numera_scansioni')
      can [:read,:numera,:update], BioIconograficoCard
    end

    if user.role?('bio_iconografico_manager')
      can :manage, [BioIconograficoTopic,BioIconograficoCard]
    end

    if user.role?('bct_letter_manager')
      can :manage, BctLetter
    else
      can :read, BctLetter
    end

    if user.role?('procultura_manager')
      can :manage, [ProculturaFolder, ProculturaCard]
    end

    if user.role?('open_shelf_manager')
      can :ricollocazioni, ClavisItem
      can :manage, OpenShelfItem
    end

    if user.role?('open_shelf_selector')
      can :ricollocazioni, ClavisItem
      can :toggle_item, OpenShelfItem, :created_by => user.id
    end

    if user.role?('ricolloca_scaffale_aperto')
      can :ricolloca_scaffale_aperto, OpenShelfItem
      can :estrazione_da_magazzino, OpenShelfItem
    end

    if user.role?('d_object_manager')
      can [:manage,:search], DObject
      can :manage, DObjectsFolder
      can :upload, OmekaFile
    end

    if user.role?('d_object_search')
      can [:search,:index,:view,:list_folder_content,:makepdf], DObject
      can [:index,:show], DObjectsFolder
    end

    if user.role?('extra_card_manager')
      can :manage, ExtraCard
    end

    if user.role?('container_manager')
      can :manage, Container
    end

    if user.role?('clavis_purchase_proposal_manager')
      can :manage, ClavisPurchaseProposal
    end

    if user.role?('clavis_loan_manager')
      can :manage, ClavisLoan
    end

    if user.role?('clavis_item_manager')
      can :manage, ClavisItem
      can :show, SchemaCollocazioniCentrale
    end

    if user.role?('clavis_item_search')
      can [:search,:index], ClavisItem
      can :show, SchemaCollocazioniCentrale
    end

    if user.role?('clavis_patron_manager')
      can [:manage], ClavisPatron
    end

    if user.role?('clavis_patron_wrong_contacts')
      can [:wrong_contacts], ClavisPatron
    end

    if user.role?('clavis_patron_mancato_ritiro')
      can [:mancato_ritiro], ClavisPatron
    end

    if user.role?('clavis_loan_goethe')
      can :view_goethe_loans, ClavisLoan
    end

    if user.role?('sp_bibliography_user')
      #can [:index, :show, :edit, :destroy, :new, :create, :update], [SpItem,SpSection] do |i|
      #  fd=File.open('/home/seb/tempdebug.txt', 'a')
      #  fd.write("#{i.class} bibliography_id: #{i.bibliography_id}\n")
      #  fd.close
      #  r=user.sp_bibliographies.collect{|i| i.id}.include?(i.bibliography_id)
      #  r
      #end
      can [:index,:create], SpBibliography
      can [:create,:edit,:update,:destroy], [SpBibliography,SpSection,SpItem] do |i|
        id = i.class == SpBibliography ? i.id : i.bibliography_id
        r = false
        if SpUser.exists?([id,user.id])
          fd=File.open('/home/seb/tempdebug.txt', 'a')
          spu = SpUser.find(id,user.id)
          r = spu.auth.split(',').include?(i.class.to_s) if !spu.auth.nil?
          fd.write("user #{user.email} auth='#{spu.auth}' - classe da autorizzare: #{i.class} - bibliography_id: #{id} - esito: #{r}\n")
          fd.close
        end
        r
      end
    end
    
    if user.role?('sp_section_manager')
      can :manage, SpSection
    end

    if user.role?('sp_bibliography_manager')
      can :manage, SpBibliography
      can :manage, SpItem
    end

    if user.role?('closed_stack_item_requests_manager')
      can [:index,:print,:confirm_request,:csir_delete,:csir_archive], ClosedStackItemRequest
    end

    if user.role?('closed_stack_item_requests_search')
      can :manage, ClosedStackItemRequest
    end

    if user.role?('clavis_patron_closed_stack_items_request')
      can :show, ClavisPatron
    end

    if user.role?('iss_page__manager')
      can :manage, IssPage
    end

    if user.role?('work_station_manager')
      can :manage, WorkStation
    end

    if user.role?('talking_book_manager')
      can :manage, TalkingBook
    end

    if user.role?('talking_book_reader_manager')
      can :manage, TalkingBookReader
    end

    if user.role?('identity_card_manager')
      can :manage, IdentityCard
    end

    if user.role?('adabas_inventory_manager')
      can :manage, AdabasInventory
    end

    if user.role?('schema_collocazioni_centrale')
      can :manage, SchemaCollocazioniCentrale
    end

    if user.role?('clavis_librarian_search')
      can  [:index,:show], ClavisLibrarian
    end

    if user.role?('manoscritto_manager')
      can :manage, Manoscritto
    end

    if user.role?('serial_manager')
      can :manage, [SerialList,SerialTitle,SerialSubscription,SerialLibrary,SerialInvoice]
    end
    if user.role?('serial_user')
      can [:index, :show, :edit, :destroy, :new, :create, :update, :print], [SerialList,SerialTitle,SerialSubscription,SerialLibrary,SerialInvoice]
    end

    if user.role?('clavis_item_request_manager')
      can :manage, ClavisItemRequest
    end

    if user.role?('acquisition_manager')
      can :manage, [SbctTitle,SbctList,SbctItem,SbctBudget,SbctInvoice,SbctSupplier]
    end

    if user.role?('acquisition_librarian')
      can [:homepage,:index,:show,:add_to_library], [SbctTitle,SbctList,SbctItem]
      can [:index,:show], [SbctBudget]
      can [:create,:edit,:update], [SbctTitle]
    end

    if user.role?('acquisition_user')
      can [:homepage,:index,:show], [SbctTitle,SbctList,SbctItem]
      can [:index,:show], [SbctBudget]
    end


  end
end
