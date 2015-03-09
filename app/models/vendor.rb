require 'mongoid'

require_relative 'form'

class Vendor < Actor
  field :name, type: String
  field :domain, type: String
  field :api_key, type: String
  field :schema, type: Hash

  has_many :forms

  def users
    Relationship.of_actor(self).map { |r| r.counterparty_of(self) }
  end

  def responses_for_query(query)
    users = if query[:users]
              query[:users].map { |x| User.find(x) }
            else
              self.users
            end
    fields = query[:fields]

    responses = users.map do |u|
      r = Relationship.between(self, u).first
      {
        user_id: u._id.to_s,
        key: r.key_for(self),
        data: Message.merge_with_components(
          nil,
          Message.by_relationship(r).has_fields
        )
      }
    end

    result = {
      fields:
        responses.map do |response|
          response[:data].keys
        end.inject([], :|),
      responses:
        responses
    }

    return result
  end
end
