# lastmod 21 febbraio 2013

class ClavisLoan < ActiveRecord::Base
  self.table_name='clavis.loan'
  self.primary_key = 'loan_id'

  belongs_to :patron, :class_name=>'ClavisPatron'
  belongs_to :item, :class_name=>'ClavisItem'
  belongs_to :manifestation, :class_name=>'ClavisManifestation'

  def self.receipts_pdf(loans)
    lp=LatexPrint::PDF.new('receipts', loans)
    lp.makepdf
  end

  def self.receipts(params={})
    library_id = params[:library_id].blank? ? 2 : params[:library_id].to_i
    ldb = params[:loan_date_begin]
    if !ldb.blank?
      ldb="and loan_date_begin='#{ldb}'" 
    else
      ldb="and loan_date_begin notnull"
    end

    sql=%Q{SELECT collocazione, title, loan_date_begin, barcode, manifestation_id,
            item_id, inventario, item_barcode from clavis.view_prestiti
  WHERE
  owner_library_id=#{library_id}
    #{ldb}
   and loan_date_end isnull
   and not collocation ~* '^DVD'
  order by section, espandi_collocazione(collocazione),
   specification, sequence1, sequence2;}
    puts sql
    return ClavisLoan.find_by_sql(sql)
  end

end
