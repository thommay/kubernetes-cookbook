#
# Cookbook Name:: kubernetes
#
# Copyright 2016 Chef Software, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

actions :create
default_action :create

property :master_ip, String, required: true
property :master_port, String, default: "8080"

property :bootstrap_docker_host, String, default: "unix:///var/run/docker-bootstrap.sock"
property :bootstrap_docker_graph, String, default: "/var/lib/docker-bootstrap"
property :bootstrap_docker_pid, String, default: "/var/run/docker-bootstrap.pid"

property :docker_host, String, default: "unix:///var/run/docker.sock"
property :insecure_registry, [String, nil], default: nil

property :flanneld_version, String, default: "0.5.5"
property :flanneld_repo, String, default: "quay.io/coreos/flannel", desired_state: false

property :kubernetes_version, String, default: "1.1.4"
property :kubernetes_repo, String, default: "gcr.io/google_containers/hyperkube"

action :create do
  converge_by "create a kubernetes node for #{name}" do

    docker_service "bootstrap" do
      action [:create, :start]

      # Ensure this instance of docker runs on a different socket
      host bootstrap_docker_host
      graph bootstrap_docker_graph
      pidfile bootstrap_docker_pid

      iptables false
      ip_masq false
      bridge "none"
    end

    docker_image "flanneld" do
      repo flanneld_repo
      tag flanneld_version
      host bootstrap_docker_host
      action :pull
    end

    docker_container "flanneld" do
      repo flanneld_repo
      tag flanneld_version
      host bootstrap_docker_host
      network_mode "host"
      volumes [ "/dev/net:/dev/net" ]
      privileged true
      command "/opt/bin/flanneld --etcd-endpoints=http://#{master_ip}:4001"
    end

    ruby_block "get flannel config" do
      block do
        require "docker"
        Docker.url = bootstrap_docker_host
        container = Docker::Container.get("flanneld")
        begin
          config = container.exec(["cat", "/run/flannel/subnet.env"], stderr: false)
          config[0][0].each_line do |ln|
            k, v = ln.split("=")
            node.run_state[k.downcase] = v.chomp
          end
        rescue NoMethodError
          retry
        end
      end
    end

    docker_service "main" do
      action [:create, :start]
      install_method "none"
      bip lazy { node.run_state["flannel_subnet"].chomp }
      mtu lazy { node.run_state["flannel_mtu"].chomp }
      host docker_host
      insecure_registry(new_resource.insecure_registry) if new_resource.insecure_registry
    end

    docker_image "hyperkube" do
      repo kubernetes_repo
      tag "v#{kubernetes_version}"
      host docker_host
    end

    docker_container "kubelet" do
      repo kubernetes_repo
      tag "v#{kubernetes_version}"
      host docker_host
      volumes ["/:/rootfs:ro", "/sys:/sys:ro", "/dev:/dev",
               "/var/lib/docker:/var/lib/docker:rw",
               "/var/lib/kubelet:/var/lib/kubelet:rw", "/var/run:/var/run:rw"]
      network_mode "host"
      privileged true
      pid_mode "host"
      command "/hyperkube kubelet --api-servers=http://#{master_ip}:#{master_port} --v=2 --address=0.0.0.0 --enable-server --hostname-override=#{node['ipaddress']} --cluster-dns=10.0.0.10 --cluster-domain=cluster.local --allow-privileged=true"
    end

    docker_container "proxy" do
      repo kubernetes_repo
      tag "v#{kubernetes_version}"
      host docker_host
      network_mode "host"
      privileged true
      command "/hyperkube proxy --master=http://#{master_ip}:#{master_port} --v=2"
    end

  end
end
