require_relative '../models/vendor'

module VendorRoutes
  def self.registered(app)
    app.get '/vendors' do
      halt_with_error 422, 'Requires a domain.' unless params[:domain]
      vendor = Vendor.find_by(domain: params[:domain])
      if vendor then vendor.to_json else not_found end
    end

    app.post '/vendors' do
      domain = @request_payload['domain']
      schema = @request_payload['schema']
      name = @request_payload['name']
      key = @request_payload['key']

      halt_with_error 422, 'Requires a public key.' unless key
      halt_with_error 422, 'Requires a schema.' unless schema
      halt_with_error 422, 'Requires a name.' unless name
      halt_with_error 422, 'Requires a domain.' unless domain

      vendor = Vendor.new(domain: domain, schema: schema, name: name, key: key)
      vendor.save!
      vendor.to_json
    end

    app.namespace '/vendors/:id' do
      before do
        @vendor = Vendor.find(params[:id])
      end

      get '/responses' do
        query = { users: params[:users], fields: params[:fields] }

        @vendor.responses_for_query(query).to_json
      end

      get '/forms' do
        @vendor.forms.to_json
      end

      post '/forms' do
        form = @vendor.forms.build(
          form_fields: @request_payload['form_fields'],
          name: @request_payload['name'],
          description: @request_payload['description']
        )
        form.save!

        form.to_json
      end
    end
  end
end

