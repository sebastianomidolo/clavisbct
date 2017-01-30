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
      can [:numera,:update], BioIconograficoCard
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
      can :manage, DObject
      can :upload, OmekaFile
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
    end

    if user.role?('clavis_item_search')
      can [:search,:index], ClavisItem
    end

    if user.role?('clavis_patron_wrong_contacts')
      can [:wrong_contacts], ClavisPatron
    end

    if user.role?('clavis_loan_goethe')
      can :view_goethe_loans, ClavisLoan
    end

    if user.role?('closed_stack_item_requests_manager')
      can :manage, ClosedStackItemRequest
    end

    if user.role?('work_station_manager')
      can :manage, WorkStation
    end

  end
end
