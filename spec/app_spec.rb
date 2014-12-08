require_relative 'spec_helper'

describe 'API' do
  it 'Homepage OK' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'creates a channel' do
    post '/channels', {'key' => 'a_cryptographic_key', 'blocks' => ['first-name']}.to_json,
         {'CONTENT_TYPE' => 'application/json'}
    expect(last_response).to be_ok
  end

  it 'fails to create channel' do
    # Uses underscore instead of hyphen
    post '/channels', {'key' => 'a_cryptographic_key', 'blocks' => ['first_name', 'last_name']}.to_json,
         {'CONTENT_TYPE' => 'application/json'}
    expect(last_response).not_to be_ok
  end

  it 'creates a channel' do
    post '/channels', {'key' => 'a_cryptographic_key'}.to_json, {'CONTENT_TYPE' => 'application/json'}
    expect(last_response).to be_ok
  end
end
