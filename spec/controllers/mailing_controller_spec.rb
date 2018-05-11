require 'rails_helper'

RSpec.describe MailingController, type: :controller do
  before { request.env['REMOTE_ADDR'] = '127.0.0.0/8' }

  let (:message_status) { FactoryGirl.create(:message_status) }
  let (:user) { FactoryGirl.create(:user) }

  describe 'GET #receive_message' do
    before do
      # added all params received just for reference
      @params_from_email = {
        "recipient"=>"conversation@messaging.intervac-homeexchange.com",
        "sender"=>user.email,
        "subject"=>"Rspec test",
        "from"=>"Aragorn <king@gondor.com>",
        "X-Mailgun-Incoming"=>"Yes",
        "X-Envelope-From"=>"<aragorn.son.of.arathorn@gmail.com>",
        "Received"=>"by mail-ob0-f169.google.com with SMTP id fz5so53017949obc.0 for (...)",
        "Dkim-Signature"=>"v=1; a=rsa-sha256; c=relaxed/relaxed; (...)",
        "X-Google-Dkim-Signature"=>"v=1; a=rsa-sha256; c=relaxed/relaxed; d=1e100.net; s=20130820; (...)",
        "X-Gm-Message-State"=>"AD7BkJ...",
        "X-Received"=>"by 10.60.35.35 with SMTP id e3mr2536260oej.27.1458139156931; Wed, 16 Mar 2016 07:39:16 -0700 (PDT)",
        "Mime-Version"=>"1.0",
        "References"=>"<CAJRLHECOjJH-b+7UPMs=oJ+Q3jc3j(...)XW=D863Bvg@mail.gmail.com>",
        "In-Reply-To"=>message_status.mailgun_id,
        "From"=>"Aragorn <king@gondor.com>",
        "Date"=>"Wed, 16 Mar 2016 14:39:07 +0000",
        "Message-Id"=>"<CAJRLHEDRYZFALNYfGSiJ_nspzn1zP823SnvDFvuUGHhOFs1hgg@mail.gmail.com>",
        "Subject"=>"Rspec test", "To"=>"conversation@messaging.intervac-homeexchange.com",
        "Content-Type"=>"multipart/alternative; boundary=\"089e0112d0147b8ed6052e2b7a7f\"",
        "message-headers"=>"[[\"a list with all the\", \"headers above\"]]",
        "timestamp"=>"1458139170",
        "token"=>"56e97fe9106447bd2d3b2b96a568485769306f074d24cbb3d3",
        "signature"=>"8b17a89c32544e4761c3f0ab9b36de657492057cab8db6345a06a94e441a27ec",
        "body-plain"=>"asrt",
        "body-html"=>"<div>a lot of html here and closes body (???)</div></body>",
        "stripped-text"=>"asrt",
        "stripped-signature"=>"",
      }
    end

    context 'receiving an email' do
      it "ignores when the message is not verified" do
        get :receive_message, @params_from_email
        expect(response).to be_ok
      end

      it "sends an undeliverable email when missing data" do
        @params_from_email["In-Reply-To"] = ''
        allow(ModondoMailgun::Verify).to receive(:verify_message).and_return(true)
        expect(NotificationMailer).to receive(:undeliverable)

        get :receive_message, @params_from_email
        expect(response).to be_ok
      end

      it "adds a new conversation when the sender is an admin or agent" do
        allow(ModondoMailgun::Verify).to receive(:verify_message).and_return(true)

        # assuming that it got into the right path
        # TODO: improve this test to see the message.count increase
        expect(Conversation).to receive(:get_status_object)

        get :receive_message, @params_from_email
        expect(response).to be_ok
      end
    end
  end
end
