require_relative '../models/block'

DEFAULT_ORGANIZATION = 'slide.life'

def is_annotation(key)
  key[0] == '_'
end

def inherits(component)
  { '_inherits' => component }
end

def component_name(component)
  component.split('.').last
end

def flatten(key, value, separator, fields)
  resolve_components(value)

  annotations = value.select { |k, v| is_annotation key }
  annotations['_children'] = []
  fields[key] = annotations

  children = value.select { |k, v| ! is_annotation key }
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
      field[component_name component] = inherits component
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

def resolve_inheritance(organization, key, fields)
  field = fields[key]

  return unless field.is_a? Hash

  if field.has_key? '_children'
    children = field['_children']
    children.each { |child| resolve_inheritance(organization, child, fields) }
  end

  if field.has_key? '_inherits'
    parent = field['_inherits']
    parent = organization + parent unless parent.include? ':'
    resolve_inheritance(organization, parent, fields)
    merge(key, parent, fields)
    fields[key].delete('_inherits')
  end
end

def remove_children(fields)
  fields.keys.each { |key| fields[key].delete('_children') }
end

module BlockRoutes
  def self.registered(app)
    app.get '/blocks' do
      organization = params['organization'] || DEFAULT_ORGANIZATION
      blocks = Block.find_by(organization: organization)
      halt_with_error 404, 'Organisation not found' if blocks.nil?

      fields = {}
      flatten(blocks.organization, blocks.schema, ':', fields)
      fields.keys.each { |key| resolve_inheritance(organization, key, fields) }
      remove_children fields
      fields.to_json
    end
  end
end
