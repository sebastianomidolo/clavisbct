class ClavisPurchaseProposal < ActiveRecord::Base
  self.table_name='clavis.purchase_proposal'
  self.primary_key = 'proposal_id'

  attr_accessible :title, :patron_id

  belongs_to :patron, :class_name=>'ClavisPatron'



  def self.list(proposal,params)
    attrib=proposal.attributes.collect {|a| a if not a.last.blank?}.compact
    cond=[]
    proposals=[]
    attrib.each do |a|
      name,value=a
      case name
      when 'title'
        ts=self.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', purchase_proposal.title) @@ to_tsquery('simple', '#{ts}')"
      when 'patron_id'

      end
    end
    if params[:patron_id].to_i>0
      cond << "purchase_proposal.patron_id=#{params[:patron_id]}"
    end
    select="purchase_proposal.*,lv.value_label as status_label,cm.manifestation_id"
    joins=%Q{JOIN clavis.lookup_value lv ON(lv.value_key=purchase_proposal.status AND value_class = 'PROPOSALSTATUS'
               AND value_language='it_IT')
             LEFT JOIN clavis.manifestation cm ON(cm."EAN"=purchase_proposal.ean AND cm."EAN" != '' AND purchase_proposal.ean!='')}
    cond = cond.join(' AND ')
    ClavisPurchaseProposal.paginate(conditions:cond,
                                    page:params[:page],
                                    select:select,
                                    joins:joins,
                                    include:'patron',
                                    :per_page=>100,
                                    :order=>'proposal_id desc')
  end 


end
