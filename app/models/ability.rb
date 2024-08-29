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
      can :manage, [BioIconograficoTopic,BioIconograficoCard,BioIconograficoNamespace]
    end

    if user.role?('clinic')
      can :use, Clinic
      # can [:index], DiscardRule
    end

    if user.role?('clinic_manager')
      can :manage, Clinic
    end

    if user.role?('discard_rules_manager')
      can :manage, DiscardRule
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
      can [:manage], DObjectsFolder
      can :upload, OmekaFile
    end

    if user.role?('d_object_search')
      can [:search,:index,:view,:list_folder_content,:makepdf], DObject
      can [:index,:show], DObjectsFolder
    end

    if user.role?('d_object_browse')
      can [:index,:view,:list_folder_content], DObject
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
      # can :show, SchemaCollocazioniCentrale
    end

    if user.role?('clavis_item_search')
      can [:search,:index], ClavisItem
      can [:show], Location
    end

    if user.role?('clavis_patron_manager')
      can [:manage], ClavisPatron
    end

    if user.role?('clavis_patron_wrong_contacts')
      can [:wrong_contacts,:duplicates], ClavisPatron
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
      can [:index,:print,:confirm_request,:csir_delete,:csir_archive,:search], ClosedStackItemRequest
    end

    #if user.role?('closed_stack_item_requests_search')
    #  can :manage, ClosedStackItemRequest
    #end

    if user.role?('closed_stack_item_requests_onoff')
      can :onoff, ClosedStackItemRequest
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
      can :manage, [TalkingBook, TalkingBookDownload]
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

    #if user.role?('schema_collocazioni_centrale')
    #  can :manage, [BibSection,Location]
    #end

    if user.role?('bib_section_manager')
      can :manage, BibSection
    end
    if user.role?('location_manager')
      can :manage, Location
    end
    if user.role?('location_search')
      can [:index,:show], [BibSection,Location]
    end

    if user.role?('clavis_item_stat')
      can [:stat], ClavisItem
    end

    if user.role?('clavis_item_scarto')
      can [:scarto,:index], ClavisItem
      can [:index], DiscardRule
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
      can [:index, :show, :edit, :destroy, :new, :create, :update, :print, :subscr], [SerialList,SerialTitle,SerialSubscription,SerialLibrary,SerialInvoice,SerialReminder]
      can [:reminders_send], [SerialReminder]
    end
    if user.role?('serial_readonly')
      can [:index, :show, :print], [SerialList,SerialTitle,SerialSubscription,SerialLibrary,SerialInvoice]
    end


    if user.role?('clavis_item_request_manager')
      can :manage, ClavisItemRequest
    end

    if user.role?('acquisition_manager')
      can :manage, [SbctTitle,SbctList,SbctItem,SbctBudget,SbctInvoice,SbctOrder,SbctSupplier,SbctLBudgetLibrary,SbctPreset,SbctLEventTitle]
      can [:update,:edit,:show], User
    end
    if user.role?('accounting')
      can [:index,:show], [SbctInvoice,SbctSupplier,SbctOrder]
      # can :homepage, SbctTitle
    end

    if user.role?('acquisition_staff_member')
      can [:manage], [SbctTitle,SbctItem]
      can [:edit,:update], SbctLEventTitle
      can [:index,:show], [SbctBudget,SbctOrder,SbctSupplier]
      can [:index,:show,:upload,:delete_old_uploads,:title, :mass_assign_titles, :mass_remove_titles], SbctList
      can [:new], SbctList do |list,user|
        r = false
        if !list.nil? and !user.nil?
          r = true if list.owner_id==user.id
        end
        fd=File.open('/home/seb/tempdebug.txt', 'w')
        if !list.nil?
          fd.write("list per user #{user.id}: #{list.inspect}\n")
        end
        fd.write("autorizzo user #{user.id}: #{r}\n")
        fd.close
        r
      end
    end

    if user.role?('acquisition_librarian')
      can [:homepage,:index,:show, :new, :create, :update, :destroy,
           :insert_item, :delivery_notes, :piurichiesti, :add_or_remove_from_tinybox, :toggle_tinybox_items], SbctTitle
      can :show, ClavisPurchaseProposal
      can [:new, :create, :show, :update, :destroy, :selection_confirm], SbctItem do |item|
        r = false
        fd=File.open('/home/seb/tempdebug_acquisition_librarian.txt', 'w')
        if !item.nil?
          fd.write("item: #{item.inspect}\n")
        end
        fd.write("autorizzo: #{r}\n")
        fd.close
        r = true
        r
      end
      can [:index, :show, :title, :mass_assign_titles, :mass_remove_titles], [SbctList]
      can [:index, :show], [SbctEvent,SbctLEventTitle,SbctItem]
      can [:index,:show], [SbctItem,SbctBudget,SbctOrder,SbctSupplier]
      # can [:show], [SbctBudget,SbctSupplier,SbctInvoice,SbctOrder,SbctList]
      # can [:create,:edit,:update], [SbctTitle]

      can [:new], SbctList do |list,user|
        r = false
        #fd=File.open('/home/seb/tempdebugx.txt', 'w')
        if !list.nil? and !user.nil?
          #fd.write("list: #{list.inspect}\n")
          #fd.write("user: #{user.inspect}\n")
          r = true if list.owner_id==user.id
        end
        #fd.write("autorizzo: #{r}\n")
        #fd.close
        r
      end
    end

    if user.role?('acquisition_user')
      can [:homepage,:index,:show], [SbctTitle]
    end

    if user.role?('acquisition_supplier')
      can [:index,:show], [SbctInvoice] do |i|
        # can [:show], [SbctOrder]
        r = true
        r
      end
    end

    if user.role?('service_user')
      can [:index, :show], Service
    end

    if user.role?('service_editor')
      can [:index, :show, :edit, :update], Service
    end

    if user.role?('service_manager')
      can :manage, Service
    end

    if user.role?('event_manager')
      can [:homepage,:index,:show], SbctTitle
      can :manage, [SbctEvent, SbctLEventTitle, SbctEventType]
    end
    if user.role?('event_librarian')
      can [:homepage,:index,:show], SbctTitle
      can :manage, SbctEvent
      can :show, SbctLEventTitle

      can [:update], SbctLEventTitle do |le,user|
        begin
          le.sbct_event.owned_by(user)
        rescue
          raise "ici user: #{user.id} - errore #{$!}"
        end
      end

      
    end
  end
end
