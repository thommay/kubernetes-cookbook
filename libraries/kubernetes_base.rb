begin
  require "kubeclient"
rescue LoadError
  Chef::Log.debug "waiting to load kubeclient"
end

module KubernetesCookbook
 class KubernetesBase < ChefCompat::Resource

    property :labels, Hash, default: {}, coerce: proc { |v| coerce_labels(v) }
    property :name, String, name_attribute: true, desired_state: false
    property :namespace, String, default: "default", desired_state: false

   def client
     @client ||= Kubeclient::Client.new("http://localhost:8080/api/", "v1")
   end

   def klass
     @klass ||= Kubeclient.const_get(@class_name)
   end

   def get_item(name, namespace)
     client.get_entity(@type_name, klass.new, name, namespace)
   end

   def create_item(obj)
     client.send("create_#{@type_name}", obj)
   end

    def coerce_labels(entry)
      if entry.is_a? Hash
        entry
      else
        Hash(entry).to_h
      end
    end

    def coerce_selector(entry)
      if entry.is_a? Hash
        entry
      else
        Hash(entry).to_h
      end
    end

 end
end
