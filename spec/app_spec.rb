require_relative 'spec_helper.rb'

describe 'API' do
  it 'Homepage OK' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'creates a bucket' do
	post '/buckets', ['first-name', 'last-name'].to_json, { 'CONTENT_TYPE' => 'application/json' }
	expect(last_response).to be_ok
  end

  it 'fails to create bucket' do
    # Uses underscore instead of hyphen
	post '/buckets', ['first_name', 'last_name'].to_json, { 'CONTENT_TYPE' => 'application/json' }
	expect(last_response).not_to be_ok
  end
end
