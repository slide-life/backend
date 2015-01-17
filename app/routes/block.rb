require_relative '../models/block'

DEFAULT_ORGANIZATION = 'slide.life'

module BlockRoutes
  def self.registered(app)
    app.get '/blocks' do
      organization = params['organization'] || DEFAULT_ORGANIZATION
      blocks = Block.find_by(organization: organization)
      halt_with_error 404, 'Organisation not found' if blocks.nil?

      blocks.to_json
    end
  end
end
