class IssIssue < ActiveRecord::Base
  self.table_name='iss.issues'

  belongs_to :journal, :class_name=>'IssJournal'
  has_many :articles, :class_name=>'IssArticle', :foreign_key=>'issue_id', :order=>:position

  def to_label
    "#{self.anno}/#{self.fascicolo}"
  end

  def numerazione
    r = "#{self.annata}, #{self.fascicolo}"
    r << " (#{self.info_fascicolo})" if self.info_fascicolo!=self.annata and !self.info_fascicolo.nil?
    r << " #{self.extra_info}"
    r
  end

  def cover_page
    sql = %Q{
      SELECT p.* FROM #{IssArticle.table_name} a, #{IssPage.table_name} p
       WHERE a.issue_id=#{self.id} AND p.article_id=a.id ORDER BY sequential limit 1;
    }
    p=IssPage.find_by_sql sql
    p.nil? ? nil : p[0]
  end
  def cover_image
    p=self.cover_page
    return nil if p.nil?
    p.pdf_2_jpg
  end

  def prepara_pdf_completo
    if File.exists?(self.pdf_cached_fname)
      # puts "esiste #{self.pdf_cached_fname}"
      return
    end
    flist=[]
    self.articles.each do |a|
      if not a.esiste_pdf_cached?
        # puts "devo creare pdf per articolo #{a.id}"
        a.prepara_pdf_completo
      end
      fn=a.pdf_cached_fname
      flist << fn
      # puts "#{fn} Size #{File.size(fn)} - #{a.esiste_pdf_cached?}"
      # break provvisorio, debug only
      # break if flist.size>0
    end
    if flist.size>0
      cmd="/usr/bin/pdfunite #{flist.join(' ')} #{self.pdf_cached_fname}"
      # puts cmd
      # puts "flist size: #{flist.size}"
      Kernel.system(cmd)
    end
    nil
  end

  def pdf_cached_fname
    config = Rails.configuration.database_configuration
    File.join(config[Rails.env]["iss_cache"], 'issues',"#{self.id}.pdf")
  end

end

