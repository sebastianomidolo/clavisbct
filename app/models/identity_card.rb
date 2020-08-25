class IdentityCard < ActiveRecord::Base
  attr_accessible :name, :lastname, :document_type, :document_number, :document_emitter, :document_expiry, :birth_date, :national_id, :email

  # validates :national_id, format: { with: /\A[A-Z]+\d+\Z/, message: "deve iniziare con lettere maiuscole e finire con un numero" }

  validates :name, presence: true
  validates :lastname, presence: true
  validates :national_id, presence: true, length: { is: 16 }
  validates :email, confirmation: true, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP } 
  # validates :email_confirmation, presence: true
  
  def doc_filepath
    return nil if !self.doc_uploaded
    File.join(IdentityCard.file_storage, self.unique_id)
  end

  def email_confirmation
    self.email
  end

  def mimetype
    fm=FileMagic.mime
    fname = self.doc_filepath
    fstat = File.stat(fname)
    fm.file(fname)
  end

  def is_image?
    self.mimetype =~ /^image/ ? true : false
  end

  def is_pdf?
    self.mimetype =~ /^application\/pdf/ ? true : false
  end

  def IdentityCard.file_storage
    '/home/storage/temp_identity_cards'
  end

end
