class IssPage < ActiveRecord::Base
  self.table_name='iss.pages'
  belongs_to :article, :class_name=>'IssArticle'

  # has_many :attachments, :as => :attachable

  def to_label
    "Page #{self.pagenumber} => Articolo \"#{self.article.title}\", Rivista \"#{self.article.issue.journal.title}\""
  end


  def d_object
    DObject.find_by_sql(%Q{select o.* from d_objects o join attachments a on (a.d_object_id=o.id)
        join iss.pages i on(a.attachable_type='IssPage' and a.attachable_id=i.id) where i.id=#{self.id}}).first
  end

  def diskfilename
    config = Rails.configuration.database_configuration
    File.join(config[Rails.env]["iss_storage"],self.imagepath)
  end

  def extract_fulltext_from_pdf
    tf = Tempfile.new("iss_page",File.join(Rails.root.to_s, 'tmp'))
    cmd=%Q{/usr/bin/pdftotext -nopgbrk "#{self.diskfilename}" #{tf.path}}
    Kernel.system(cmd)
    tf.close(false)
    d=File.read(tf.path)
    tf.close(true)
    d
  end

  def fulltext_store
    o=self.d_object
    text=self.extract_fulltext_from_pdf.encode(:xml=>:text)
    o.edit_tags(fulltext:text)
    o.save
    true
  end

  def fulltext
    self.d_object.xmltag(:fulltext)
  end


end
