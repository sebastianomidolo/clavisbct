class Notifications < ActionMailer::Base
  default from: "bct_notifications@comperio.it"
  # add_template_helper(OrdiniHelper)
  add_template_helper(TalkingBooksHelper)
  add_template_helper(ClavisManifestationsHelper)
  

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications.alert.subject
  #
  def alert
    @greeting = "Hi"
    @talking_books = TalkingBook.find(:all,:limit=>10, :order=>'chiave,ordine')
    
    mail(to: "sebastiano.midolo@comune.torino.it", subject: "Prova invio email da ClavisBCT", reply_to: "midseb@yahoo.it")
    # mail(to: "midseb@yahoo.it", subject: "Prova invio email da rails")
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications.test.subject
  #
  def test
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
