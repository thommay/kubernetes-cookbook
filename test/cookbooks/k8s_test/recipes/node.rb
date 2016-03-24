execute "apt-get update" do
  only_if {node["platform_family"] == "debian"}
end.run_action(:run)

kubernetes_node "node 1" do
  master_ip "192.168.56.100"
  insecure_registry 'insecure_reg.com:5000'
end
