module KubernetesCookbook
  class KubernetesService < KubernetesBase

    # Service is a named abstraction of software service (for example, mysql) consisting of local port (for example 3306) that the proxy listens on, and the selector that determines which pods will answer requests sent through the proxy.
    use_automatic_resource_name
    @class_name = "Service"
    @type_name = "service"

    property :ports, Array, required: true, coerce: proc { |v| coerce_ports(v) }
    property :selector, [Hash, nil], default: {}, coerce: proc { |v| coerce_selector(v) }
    property :cluster_ip, [String, nil], default: ""
    property :type, [String, nil], default: "ClusterIP"
    property :external_ips, [Array, nil]
    property :session_affinity, String, default: "None"
    property :load_balancer_ip, [String, nil]

    def coerce_ports(entry)
      entry.map { |v| Hash(v).to_h }
    end

    load_current_value do
      retries = 3
      begin
        current = get_item(name, namespace)
        labels current.metadata.labels

        ports current.spec.ports
        selector current.spec.selector
        cluster_ip current.spec.clusterIP
        type current.spec.type
        external_ips current.spec.externalIPs
        deprecated_public_ips current.spec.deprecatedPublicIPs
        session_affinity current.spec.sessionAffinity
        load_balancer_ip current.spec.loadBalancerIP

      rescue Errno::ECONNREFUSED
        retries -= 1
        retry if retries >= 1
      rescue ::KubeException
        current_value_does_not_exist!
      end
    end

    action :create do
      converge_if_changed do
        obj = klass.new
        obj.metadata = {}
        obj.metadata.name = name
        obj.metadata.namespace = namespace
        obj.metadata.labels = labels

        obj.spec = {}
        obj.spec.ports = ports
        obj.spec.selector = selector
        obj.spec.clusterIP = cluster_ip
        obj.spec.type = type
        obj.spec.externalIPs = external_ips
        obj.spec.deprecatedPublicIPs = deprecated_public_ips
        obj.spec.sessionAffinity = session_affinity
        obj.spec.loadBalancerIP = load_balancer_ip

        create_item(obj)
      end
    end

  end
end
