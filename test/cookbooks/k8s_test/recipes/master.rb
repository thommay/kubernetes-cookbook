execute "apt-get update" do
  only_if {node["platform_family"] == "debian"}
end.run_action(:run)

node.set['build-essential']['compile_time'] = true
include_recipe "build-essential"

chef_gem 'kubeclient' do
  compile_time true
end

require 'kubeclient'

kubernetes_master "my master"

kubernetes_service "nginx" do
  ports [{:protocol=>"TCP", :port=>80, :targetPort=>80}]
  selector({:run=>"nginx"})
  cluster_ip "10.0.0.159"
end
