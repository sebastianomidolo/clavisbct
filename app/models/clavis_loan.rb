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

    per_centrale = library_id==2 ? "AND NOT cl.primo_elemento in ('DVD','BCTA','LP', 'SAP')" : ''
    
    sql=%Q{SELECT vp.collocazione, cl.piano, title, loan_date_begin, barcode, manifestation_id,
            item_id, inventario, item_barcode from clavis.view_prestiti vp
          JOIN clavis.collocazioni cc using(item_id)
          LEFT JOIN clavis.centrale_locations cl using(item_id)
  WHERE
  home_library_id=#{library_id}
    #{ldb}
   and loan_date_end isnull
   AND NOT vp.collocazione ~ '^CC' #{per_centrale}
   -- and item_media in ('F','H')
  order by cl.piano, espandi_collocazione(cc.sort_text);}
    puts sql
    return ClavisLoan.find_by_sql(sql)
  end

  def ClavisLoan.loans_report(params={})
    cond=[]
    cond << "item_id!=0"
    # cond << "loan_date_begin >= #{self.connection.quote(params[:loan_date_begin])}" if !params[:loan_date_begin].blank?
    # cond << "loan_date_end   <= #{self.connection.quote(params[:loan_date_end])}"   if !params[:loan_date_end].blank?
    # cond << "loan_date_begin BETWEEN '#{params[:begin_from]}' AND '#{params[:begin_to]}'" if !params[:begin_from].blank? AND !params[:begin_to].blank?
    cond << "loan_date_begin BETWEEN '#{params[:begin_from]}' AND '#{params[:begin_to]}'"
    where = cond == [] ? '' : "WHERE #{cond.join(' and ')}"
    sql_loans=%Q{SELECT md5(patron_id::text) as patron_id_md5,
                  patron_id,
                  item_id,
                  loan_date_begin,
                  loan_date_end,
                  due_date,
                  from_library,
                  to_library,
                  end_library
                  FROM clavis.loan #{where}}
    puts sql_loans
    tn="reports.loans"
    self.connection.execute("DROP TABLE if exists #{tn}; CREATE TABLE #{tn} as #{sql_loans}")

    sql_patrons = %Q{
       SELECT patron_id, md5(patron_id::text) as patron_id_md5,
         registration_library_id, preferred_library_id, gender, title, civil_status, date_created, last_seen
            FROM clavis.patron where patron_id in (select patron_id from reports.loans)}
    tn="reports.patrons"
    self.connection.execute("DROP TABLE if exists #{tn}; CREATE TABLE #{tn} as #{sql_patrons}")

    sql_items = %Q{
       SELECT item_id, manifestation_id, item_media, home_library_id,
              inventory_date
       FROM clavis.item where item_id in (select item_id from reports.loans);
    }
    tn="reports.items"
    self.connection.execute("DROP TABLE if exists #{tn}; CREATE TABLE #{tn} as #{sql_items}")

    sql_manifestations = %Q{
       SELECT manifestation_id,
               -- bib_level, bib_type, bib_type_first, manifestation_status,
               edition_language, edition_date, "ISBNISSN", "EAN",
               trim(title) as title, author, publisher, loanable_since, date_created
       FROM clavis.manifestation where manifestation_id in (select manifestation_id from reports.items);
    }
    tn="reports.manifestations"
    self.connection.execute("DROP TABLE if exists #{tn}; CREATE TABLE #{tn} as #{sql_manifestations}")

    self.connection.execute(%Q{
           alter table reports.loans drop column patron_id;
           alter table reports.patrons drop column patron_id;
           create unique index reports_patrons_patron_id_md5 on reports.patrons(patron_id_md5);
           alter table reports.loans add constraint patron_id_md5_fkey FOREIGN KEY(patron_id_md5)
             REFERENCES reports.patrons(patron_id_md5);
           create unique index reports_items_item_id on reports.items(item_id);
           alter table reports.loans add constraint item_id_fkey FOREIGN KEY(item_id) REFERENCES reports.items(item_id);
           -- Questi sono i fuori catalogo, che ci danno un bel problema:
           update reports.items set manifestation_id=NULL where manifestation_id=0;
           create unique index reports_manifestations_manifestation_id on reports.manifestations(manifestation_id);
           alter table reports.items add constraint manifestation_id_fkey FOREIGN KEY(manifestation_id)
               REFERENCES reports.manifestations(manifestation_id)})
  end

  def ClavisLoan.loans_by_supplier(supplier_id, params)
    page = params[:page].blank? ? 1 : params[:page].to_i
    per_page = params[:per_page].blank? ? 40 : params[:per_page].to_i
    order = params[:order].blank? ? '' : "ORDER BY #{params[:order]}"
    
    date_filter = ''
    if params[:date_from]
      date_filter << " AND vp.loan_date_begin >= #{ClavisLoan.connection.quote(params[:date_from])}"
    end
    if params[:date_to]
      date_filter << " AND vp.loan_date_begin < #{ClavisLoan.connection.quote(params[:date_to])}"
    end
    
    sql=%Q{SELECT l.*, vp.*, case when p.gender is null then '?' else p.gender end as gender,
           p.citizenship,
           ci.title, ci.manifestation_id FROM clavis.view_prestiti2 vp
             JOIN clavis.loan l using(loan_id) JOIN clavis.item ci on (ci.item_id=l.item_id)
             LEFT JOIN clavis.patron p on(p.patron_id=l.patron_id)
         WHERE supplier_id=#{supplier_id.to_i} AND vp.loan_date_begin NOTNULL #{date_filter} #{order}}
    if !params[:view].blank?
      page=1
      per_page=999999
    end
    ClavisLoan.paginate_by_sql(sql, per_page:per_page, page:page)
  end
end
