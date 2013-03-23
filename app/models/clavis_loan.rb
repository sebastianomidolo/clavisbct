# lastmod 21 febbraio 2013

class ClavisLoan < ActiveRecord::Base
  self.table_name='clavis.loan'
  self.primary_key = 'loan_id'

  belongs_to :patron, :class_name=>'ClavisPatron'
  belongs_to :item, :class_name=>'ClavisItem'
  belongs_to :manifestation, :class_name=>'ClavisManifestation'

  def self.receipts_pdf(loans)
    lp=LatexPrint::PDF.new('receipts', loans)
    # lp=LatexPrint::PDF.new('receipts', ClavisLoan.split_receipts(loans))
    lp.makepdf
  end

  def self.split_receipts(loans, per_page=9)
    total = loans.size
    remaining = total % per_page
    if remaining > 0
      # num_pages += 1
      theloans = loans.shift(total - remaining)
      other_loans=loans
    else
      theloans = loans
      other_loans=[]
    end
    num_pages = total / per_page
    # puts "#{total} scontrini, servono #{num_pages} pagine (resto: #{remaining})"
    # puts "theloans: #{theloans.size} - other_loans: #{other_loans.size}"
    return loans if theloans.size==0
    # h={};i=0;theloans.collect {|l| h[i]=l; i+=1}
    
    step = total/(total/num_pages)
    # puts "step: #{step}"
    res=[]
    # i=1;(1..4).collect {|page| (1..9).each {|t| puts t; t}}
    (1..num_pages).each do |page|
      seq=page
      (1..per_page).each do |t|
        # puts "scontrino numero #{t} => #{seq-1} (su #{theloans.size})"
        # puts theloans[seq-1].class
        res << theloans[seq-1]
        seq+=step
      end
    end
    res + other_loans
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
   and item_media in ('F','H')
  order by section, espandi_collocazione(collocazione),
   specification, sequence1, sequence2;}
    # puts sql
    return ClavisLoan.find_by_sql(sql)
  end

end
