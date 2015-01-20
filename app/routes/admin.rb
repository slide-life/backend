require_relative '../models/vendor'

module AdminRoutes
  def self.registered(app)
    app.post '/admin/vendors' do
      vendor = Vendor.new name: @request_payload['name'],
        description: @request_payload['description']

      vendor.save!
      vendor.to_json
    end
  end
end
