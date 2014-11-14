require_relative 'spec_helper.rb'

describe 'API' do
  it 'Homepage OK' do
    get '/'
    expect(last_response).to be_ok
  end
end
