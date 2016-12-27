require "rails_helper"

RSpec.describe Notifications, :type => :mailer do
  describe "alert" do
    let(:mail) { Notifications.alert }

    it "renders the headers" do
      expect(mail.subject).to eq("Alert")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "test" do
    let(:mail) { Notifications.test }

    it "renders the headers" do
      expect(mail.subject).to eq("Test")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
