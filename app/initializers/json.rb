# Initializers
module BSON
  class ObjectId
    alias :to_json :to_s
  end
end

module Mongoid
  module Document
    def to_json(options={})
      attrs = super(options)
      attrs['id'] = attrs['_id']
      attrs.delete '_id' #TODO modify this to actually delete it, not for now though
      attrs
    end
  end
end
