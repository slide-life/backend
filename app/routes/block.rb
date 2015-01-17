require_relative '../models/block'

def flatten(key, value, separator, fields)
  resolve_components(value)
  fields[key] = value.select { |k, v| k[0] == '_' }
  fields[key]['_children'] = []
  children = value.select { |k, v| k[0] != '_' }
  children.each do |k, v|
    child_name = "#{key}#{separator}#{k}"
    fields[key]['_children'] << child_name
    flatten(child_name, v, '.', fields) if v.is_a? Hash
  end
end

def resolve_components(field)
  if field.has_key? '_components'
    components = field['_components']
    components.each do |component|
      field[component.split('.').last] = { '_inherits' => component }
    end
    field.delete('_components')
  end
end

def merge(to, from, fields)
  from_field = fields[from] || {}
  to_field = fields[to] || {}

  from_children = from_field['_children']
  from_children.each do |from_child|
    to_child = from_child.sub(from, to)
    merge(to_child, from_child, fields)
    to_field['_children'] << to_child
  end

  merged = from_field.select { |k,v| k != '_children' }.merge(to_field)
  fields[to] = merged
end

def resolve_inheritance(key, fields)
  field = fields[key]

  return unless field.is_a? Hash

  if field.has_key? '_children'
    children = field['_children']
    children.each { |child| resolve_inheritance(child, fields) }
  end

  if field.has_key? '_inherits'
    parent = field['_inherits']
    parent = 'slide.life:' + parent unless parent.include? ':'
    resolve_inheritance(parent, fields)
    merge(key, parent, fields)
    fields[key].delete('_inherits')
  end
end

module BlockRoutes
  def self.registered(app)
    app.get '/blocks' do
      blocks = Block.all[0]
      fields = {}
      flatten blocks.organization, blocks.schema, ':', fields
      fields.keys.each { |key| resolve_inheritance(key, fields) }
      fields.to_json
    end
  end
end
