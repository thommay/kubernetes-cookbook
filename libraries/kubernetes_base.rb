begin
  require "kubeclient"
rescue LoadError
  Chef::Log.debug "waiting to load kubeclient"
end

module KubernetesCookbook
  class KubernetesBase < ChefCompat::Resource
    attr_accessor :class_name, :type_name

    property :labels, Hash, default: {}, coerce: proc { |v| coerce_labels(v) }
    property :name, String, name_attribute: true, desired_state: false
    property :namespace, String, default: "default", desired_state: false

    def client
      @client ||= Kubeclient::Client.new("http://localhost:8080/api/", "v1")
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
