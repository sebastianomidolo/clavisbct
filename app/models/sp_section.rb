class SpSection < ActiveRecord::Base
  self.table_name='sp.sp_sections'
  self.primary_keys = :bibliography_id, :number

  before_save :check_section_title
  after_save :update_sp_items
  before_destroy :rearrange_sections

  attr_accessible :number, :parent, :sortkey, :title, :status, :bibliography_id, :description, :clavis_shelf_id, :updated_by, :clavis_patron_id, :homepage, :location_id

  belongs_to :sp_bibliography, :foreign_key=>'bibliography_id'
  belongs_to :clavis_shelf, foreign_key: :clavis_shelf_id
  belongs_to :location, foreign_key: :location_id

  def sp_items(order=nil)
    orderby = order.nil? ? "lower(trim(regexp_replace(sort_text, '[^a-zA-Z0-9 ]', '', 'g')))" : "public.espandi_collocazione(collciv)"
    sql = %Q{with t1 as
         (SELECT *,
           case when (mainentry is null or mainentry='') then (case when sortkey is null then bibdescr else sortkey end)
             else mainentry || '  ' || (case when sortkey is null then bibdescr else sortkey end) end as sort_text
         FROM sp.sp_items WHERE bibliography_id = '#{self.bibliography_id}' and section_number=#{self.number})
           SELECT *,lower(trim(regexp_replace(sort_text, '[^a-zA-Z0-9 ]', '', 'g'))) as truesortkey
           from t1 order by #{orderby} collate "C";}
    # puts sql
    SpItem.find_by_sql(sql)
  end

  def to_label
    self.title
  end
  
  def sp_sections(logged_in=true)
    puts "logged_in: #{logged_in}"
    cond = logged_in ? '' : "and status='1'"
    sql=%Q{SELECT * FROM sp.sp_sections WHERE bibliography_id = '#{self.bibliography_id}' and parent=#{self.number} #{cond} order by sortkey,title}
    SpSection.find_by_sql(sql)
  end

  def parent_section
    return nil if self.parent==0
    SpSection.find_by_bibliography_id_and_number(self.bibliography_id, self.parent)
  end

  def items_import_from_clavis_shelf
    library_id=self.sp_bibliography.library_id
    return [] if self.clavis_shelf_id.nil?
    sql=%Q{delete from sp.sp_items where bibliography_id=#{self.bibliography_id} and section_number=#{self.number};}
    ClavisShelf.soap_get_records_in_shelf(self.clavis_shelf_id)
    self.connection.execute(sql)
    ClavisManifestation.in_shelf(self.clavis_shelf_id,library_id,10000).each do |r|
      # puts r.inspect
      item = SpItem.new(manifestation_id:r.manifestation_id,bibliography_id:self.bibliography_id,section_number:self.number,collciv:r.collocazione)
      item.save
    end
    nil
  end

  def update_sp_items
    return items_import_from_locations if !self.location_id.nil?

    if !self.clavis_patron_id.nil?
      self.items_import_from_patron_loans
    else
      self.items_import_from_clavis_shelf
    end
  end

  def items_import_from_locations
    return [] if self.location_id.nil?
    library_id=self.sp_bibliography.library_id
    location=Location.find(self.location_id)
    sql = %Q{
      BEGIN;
       delete from sp.sp_items where bibliography_id=#{self.bibliography_id} and section_number=#{self.number};
    with titles as
    (SELECT ci.manifestation_id,cc.collocazione,
           a.full_text as mainentry,
           case when i.isbd is null then trim(ci.title) else i.isbd end as bibdescr
      from public.locations l
       join clavis.collocazioni cc on(cc.location_id=l.id)
       join clavis.item ci using(item_id)
       LEFT JOIN public.isbd i on(i.manifestation_id=ci.manifestation_id)
       left join clavis.l_authority_manifestation lam on(lam.manifestation_id=ci.manifestation_id
	        and lam.link_type=700)
       left join clavis.authority a using(authority_id)
        where l.id=#{self.location_id} and ci.manifestation_id>0
        group by 1,2,3,4
      )
--       select * from titles where manifestation_id=960853;
      INSERT INTO sp.sp_items (bibliography_id,section_number,manifestation_id,bibdescr,mainentry,collciv)
         (select #{self.bibliography_id},#{self.number},manifestation_id,bibdescr,mainentry,collocazione from titles);
      COMMIT;
    }
    # puts sql
    self.connection.execute(sql)
    nil
  end
  
  def items_import_from_patron_loans
    return if self.clavis_patron_id.nil?
    patron=ClavisPatron.find(self.clavis_patron_id)
    puts "Importazione titoli prestati a #{patron.to_label}"
    sql = %Q{
      BEGIN;
       delete from sp.sp_items where bibliography_id=#{self.bibliography_id} and section_number=#{self.number};
     with titles as
       (SELECT cl.item_id,cc.collocazione,
        a.full_text as mainentry,
        case when i.isbd is null then trim(cl.title) else i.isbd end as bibdescr,
         array_agg(loan_id order by loan_id) as loan_ids,
      array_agg(EXTRACT(EPOCH FROM (cl.loan_date_end - cl.loan_date_begin)) order by loan_id) AS seconds,
      case when cl.manifestation_id=0 then NULL else cl.manifestation_id end as manifestation_id,
      array_agg(cl.loan_date_begin order by loan_id) as loan_date_begin,
      array_agg(cl.loan_date_end order by loan_id) as loan_date_end,
      array_agg(cl.loan_status order by loan_id) as loan_status
       FROM clavis.loan cl LEFT JOIN public.isbd i using(manifestation_id)
        JOIN clavis.collocazioni cc using(item_id)
        left join clavis.l_authority_manifestation lam on(lam.manifestation_id=cl.manifestation_id
	        and lam.link_type=700)
        left join clavis.authority a using(authority_id)
       WHERE patron_id=#{patron.id}
       and EXTRACT(EPOCH FROM (cl.loan_date_end - cl.loan_date_begin)) >= 3600
      group by cl.item_id,cc.collocazione,mainentry,bibdescr,cl.manifestation_id)
      -- select * from titles;
      INSERT INTO sp.sp_items (bibliography_id,section_number,manifestation_id,bibdescr,mainentry,collciv,note)
         (select #{self.bibliography_id},#{self.number},manifestation_id,bibdescr,mainentry,collocazione,
         clavis_loans_dates_info(loan_date_begin, loan_date_end) from titles);
       COMMIT;
      }
    # puts sql
    self.connection.execute(sql)
    nil
  end

  def check_section_title
    if !self.location_id.nil?
      self.title=Location.find(self.location_id).to_label if self.title.blank?
    end

    if self.clavis_shelf_id.nil?
      return if self.clavis_patron_id.nil?
      patron=ClavisPatron.find(self.clavis_patron_id)
      # self.title="Libri prestati a #{patron.to_label} [#{patron.id}]"
      self.title="Libri prestati a [#{patron.id}]"
      self.status='0'
      return
    end
    shelf = ClavisShelf.find(clavis_shelf_id)
    self.title=shelf.shelf_name if self.title.blank?
    self.description=shelf.shelf_description if self.description.blank?
  end

  def rearrange_sections
    sql=%Q{UPDATE sp.sp_sections set parent=#{self.parent} WHERE bibliography_id=#{self.bibliography_id} AND parent=#{self.number}}
    self.connection.execute(sql)
  end

  def published?
    return false if !self.sp_bibliography.published?
    sql=%Q{with recursive sections as (
  select number,parent,title,status from sp.sp_sections where bibliography_id=#{self.bibliography_id}
         and number=#{self.number}
  UNION ALL
  select p.number,p.parent,p.title,p.status from sp.sp_sections p
     INNER JOIN sections s ON (s.parent = p.number)
     WHERE bibliography_id=#{self.bibliography_id}
  )
  select * from sections where status='0';}
    # puts sql
    self.connection.execute(sql).ntuples==0 ? true : false
  end

  def status_label
    SpSection.status_select.each do |s|
      return s[0] if s[1]==self.status
    end
    nil
  end

  def SpSection.status_select
    [
      ['Non pubblicata', '0'],
      ['Pubblicata', '1'],
    ]
  end

end
