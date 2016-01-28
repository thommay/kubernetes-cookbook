require 'json'
require 'kubeclient'
require 'pp'
require 'erubis'

API_SPEC = "v1.json"

class String
  def to_underscore!
    gsub!(/([^A-Z])([A-Z][a-z])/, '\1_\2')
    gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    tr!("- ", "_")
    downcase!
  end

  def to_underscore
    dup.tap { |s| s.to_underscore! }
  end
end

def model_name(name)
  name.split(".")[1]
end

def parse_model(name, breadcrumb="")
  name = "v1.#{name}" unless name.start_with?("v1")
  puts "Parsing #{name}"
  puts "for #{breadcrumb}" unless breadcrumb.empty?
  model = @models[name]
  return if model.nil?
  m = {}

  if breadcrumb.empty?
    m["name"] = model_name(name)
    m["description"] = model["description"]
  end

  model["properties"].each do |n, prop|
    next if %w{metadata status apiVersion kind}.include? n
    m[n] ||= {}

    m[n]["property_name"] = if !breadcrumb.empty? && breadcrumb != "spec"
                              "#{breadcrumb}_#{n}"
                            else
                              n
                            end.to_underscore

    if !breadcrumb.empty? && breadcrumb != "spec"
      m[n]["child"] = true 
      m[n]["parent"] = breadcrumb
      m[n]["real_name"] = n
    end

    m[n]["required"] = true if model.key?("required") && model["required"].include?(n)

    if prop.key?("$ref")
      if prop["$ref"] == "v1.ObjectReference"
        m[n]["type"] = "ObjectReference"
      elsif prop["$ref"] == "v1.LocalObjectReference"
        m[n]["type"] = "LocalObjectReference"
      else
        m[n] = parse_model(prop["$ref"], n)
      end

    elsif prop.key?("type")
      type = if prop["type"] == "array" && prop.key?("items")
                       if prop["items"].key?("$ref")
                         model_name(prop["items"]["$ref"]) + "Array"
                       else
                         "Array"
                       end
                     elsif prop["type"] == "boolean"
                       "[TrueClass, FalseClass]"
                     elsif prop["type"] == "any"
                       "Hash"
                     else
                       prop["type"].capitalize
                     end

      m[n]["type"] = if m[n]["required"]
                       type
                     elsif prop["type"] == "boolean"
                       "[TrueClass, FalseClass, nil]"
                     else
                       "[#{type}, nil]"
                     end
    end

    m[n]["description"] = prop["description"] unless n == "spec"
  end
  m
end

task :generate do
  input = File.read("generator/templates/kubernetes_resource.erb")
  erb = Erubis::Eruby.new(input)

  api = JSON.parse(File.read(API_SPEC))
  @models = api["models"]
  Kubeclient::Client::ENTITY_TYPES.each do |_, type|
    next if type == "Endpoint"
    snake = type.to_underscore
    t = parse_model(type)
    b = { class_name: type, snake_name: snake}
    b[:description] = t.delete("description")
    b[:properties] = t.delete("spec")

    next if b[:properties].nil?
    out = erb.evaluate(b)
    File.open("libraries/generated_kubernetes_#{snake}.rb", "w") { |fh| fh.write out }
  end
end
