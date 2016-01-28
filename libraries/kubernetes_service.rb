module KubernetesCookbook
  class KubernetesService < KubernetesBase

    use_automatic_resource_name
    @type_name = "Service"

    property :selector, Hash, default: {}, coerce: proc { |v| coerce_selector(v) }
    property :cluster_ip, [String, nil], default: ""
    property :type, String, default: "ClusterIP"
    property :external_ips, [Array, nil]
    property :session_affinity, String, default: "None"
    property :load_balancer_ip, [String, nil]

    property :ports, Array, required: true, coerce: proc { |v| coerce_ports(v) }

    def coerce_ports(entry)
      entry.map { |v| Hash(v).to_h }
    end

    load_current_value do
      retries = 3
      begin
        service = client.get_service(name, namespace)
        labels service.metadata["labels"]
        selector service.spec.selector
        ports service.spec.ports
        cluster_ip service.spec.clusterIP
        type service.spec.type
        external_ips service.spec.externalIPs
        session_affinity service.spec.sessionAffinity
        load_balancer_ip service.spec.loadBalancerIP
      rescue Errno::ECONNREFUSED
        retries -= 1
        retry if retries >= 1
      rescue ::KubeException
        current_value_does_not_exist!
      end
    end

    action :create do
      converge_if_changed do
        service = Kubeclient::Service.new
        service.metadata = {}
        service.metadata.name = name
        service.metadata.namespace = namespace
        service.metadata.labels = labels
        service.spec = {}
        service.spec.selector = selector
        service.spec.ports = ports
        service.spec.type = type
        service.spec.sessionAffinity = session_affinity
        service.spec.loadBalancerIP = load_balancer_ip unless load_balancer_ip.nil?
        service.spec.clusterIP = cluster_ip unless cluster_ip.nil?
        service.spec.externalIPs = external_ips unless external_ips.nil?

        client.create_service(service)
      end
    end

  end
end
