require_relative '../models/block'

module BlockRoutes
  def self.registered(app)
    app.get '/blocks' do
      Block.all.to_json
    end
  end
end
