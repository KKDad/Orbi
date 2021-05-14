require 'test_helper'

class SessionTest < Minitest::Test

  def test_login_logoff_success

    stub_request(:get, "http://myrouter.com/start.htm").
    with(
      headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby'
      }).
    to_return(status: 401, body: "", headers: {'Set-Cookie' => 'XSRF_TOKEN=2516634438; Path=/', 
                                               'WWW-Authenticate' => 'Basic realm="NETGEAR RBR850"' })

    stub_request(:get, "http://myrouter.com/start.htm").
    with(
      headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
            'Cookie' => 'XSRF_TOKEN=2516634438'
      }).
    to_return(status: 200, body: "", headers: { })

    stub_request(:get, "http://myrouter.com/LGO_logout.htm").
    with(
      headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Cookie'=>'XSRF_TOKEN=2516634438',
            'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: "", headers: {})    


    session = Orbi::Session.login('myrouter.com', 'myuser', 'mypassword', https: false)

    refute session.nil?
    assert session.xsrf_token == 'XSRF_TOKEN=2516634438'
    assert session.status
   
    session.logout
    assert session.xsrf_token.nil?
    assert !session.status

  end
end