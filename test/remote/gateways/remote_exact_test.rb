require 'test_helper'

class RemoteExactTest < Test::Unit::TestCase
  def setup
    @gateway = ExactGateway.new(fixtures(:exact))
    @credit_card = credit_card
    @amount = 100
    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_match %r{Transaction Normal}, response.message
    assert_success response
  end

  def test_unsuccessful_purchase
    # ask for error 13 response (Amount Error) via dollar amount 5,000 + error
    @amount = 501300
    assert response = @gateway.purchase(@amount, @credit_card, @options )
    assert_match %r{Transaction Normal}, response.message
    assert_failure response
  end

  def test_purchase_and_credit
    assert purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    assert purchase.authorization
    assert credit = @gateway.credit(@amount, purchase.authorization)
    assert_success credit
  end

  def test_authorize_and_capture
    assert auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert auth.authorization
    assert capture = @gateway.capture(@amount, auth.authorization)
    assert_success capture
  end

  def test_failed_capture
    assert response = @gateway.capture(@amount, 'bogus')
    assert_failure response
    assert_match %r{Invalid Transaction Tag}i, response.message
  end

  def test_invalid_login
    gateway = ExactGateway.new( :login    => "NotARealUser",
                                :password => "NotARealPassword" )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_match %r{^Invalid Login}, response.message
    assert_failure response
  end
end
