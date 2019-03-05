class IssArticle < ActiveRecord::Base
  self.table_name='iss.articles'
  belongs_to :issue, :class_name=>'IssIssue'
  has_many :pages, :class_name=>'IssPage', :order=>:position, :foreign_key=>:article_id


  def d_objects
    DObject.find_by_sql(%Q{select d.* from d_objects d join attachments a
      on(d.id=a.d_object_id) join iss.pages p
      on(p.id=a.attachable_id and attachable_type='IssPage') where p.id in
     (select id from iss.pages where article_id=#{self.id}) order by p."position";})
  end

  def sta_in
    pages=self.pages
    if !pages[0].nil?
      page = pages[0].pagenumber.nil? ? '?' : pages[0].pagenumber
    else
      page="?"
    end
    "#{self.issue.journal.title}, #{self.issue.numerazione}, pag. #{page.gsub(/^0*/,'')}"
  end

  def rivista
    self.issue.journal.title
  end

  def conta_pagine
    IssPage.count(:conditions => "article_id = #{self.id}")
  end

  def prepara_pdf_completo
    return self.cached_pdf if self.esiste_pdf_cached?
    tf = Tempfile.new("iss_article",File.join(Rails.root.to_s, 'tmp'))
    pdf_file=tf.path

    filelist = []
    self.pages.collect {|p| filelist << p.diskfilename if File.exists?(p.diskfilename)}
    filelist = filelist.join(' ')
    comando = "/usr/bin/gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{pdf_file} #{filelist}"
    if Kernel.system(comando)
      fd = File.open(pdf_file)
      data = fd.read
      fd.close
      msg = "ok"
    else
      msg = "err"
    end
    tf.close(true)
    fd=File.open(self.pdf_cached_fname,'w')
    fd.write(data)
    fd.close
    data
  end
  def cached_pdf
    File.read(self.pdf_cached_fname)
  end
  def esiste_pdf_cached?
    fname=self.pdf_cached_fname
    return true if File.exists? fname and File.readable? fname and File.size(fname)>0
    false
  end


  def pdf_cached_fname
    config = Rails.configuration.database_configuration
    File.join(config[Rails.env]["iss_cache"], 'articles',"#{self.id}.pdf")
  end

end
