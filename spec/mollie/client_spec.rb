require 'spec_helper'

describe Mollie::Client do

  let(:api_key) { "test_4drFuX5HdjBaFxdXoaABYD8yO4HjuT" }

  context '#prepare' do

    it "will setup the payment on mollie" do

      VCR.use_cassette('prepare_payment') do
        client = Mollie::Client.new(api_key)
        amount = 99.99
        description = "My fantastic product"
        redirect_url = "http://localhost:3000/payments/1/update"
        response = client.prepare_payment(amount, description, redirect_url, {:order_id => "R232454365"})

        expect(response["id"]).to eql "tr_ALc7B2h9UM"
        expect(response["mode"]).to eql "test"
        expect(response["status"]).to eql "open"
        expect(response["amount"]).to eql "99.99"
        expect(response["description"]).to eql description

        expect(response["metadata"]["order_id"]).to eql "R232454365"

        expect(response["links"]["paymentUrl"]).to eql "https://www.mollie.nl/payscreen/pay/ALc7B2h9UM"
        expect(response["links"]["redirectUrl"]).to eql redirect_url
      end
    end
  end

  context "issuers" do
    it "returns a hash with the iDeal issuers" do
      VCR.use_cassette('get_issuers_list') do
        client = Mollie::Client.new(api_key)
        response = client.issuers
        expect(response.first[:id]).to eql "ideal_TESTNL99"
        expect(response.first[:name]).to eql "TBM Bank"
      end
    end
  end

  context 'status' do
    context 'when payment is paid' do
      it "returns the paid status" do
        VCR.use_cassette('get_status_paid') do
          client = Mollie::Client.new(api_key)
          response = client.payment_status("tr_8NQDMOE7EC")
          expect(response["status"]).to eql "paid"
        end
      end
    end
  end

  context "refund" do
    it "refunds the payment" do
      VCR.use_cassette('refund payment') do
        client = Mollie::Client.new(api_key)
        response = client.refund_payment("tr_8NQDMOE7EC")
        expect(response["payment"]["status"]).to eql "refunded"
      end
    end
  end

  context "error response" do
    it "will raise an Exception" do
      VCR.use_cassette('invalid_key') do
        client = Mollie::Client.new(api_key << "foo")
        response = client.refund_payment("tr_8NQDMOE7EC")
        expect(response["error"]).to_not be nil
      end
    end
  end

end
