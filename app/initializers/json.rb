module BSON
  class ObjectId
    alias :as_json :to_s
  end
end

module Mongoid
  module Document
    def as_json(options={})
      attrs = super(options)
      json = { id: attrs['_id'] }
      attrs.delete '_id'
      json.merge! attrs
    end
  end
end
