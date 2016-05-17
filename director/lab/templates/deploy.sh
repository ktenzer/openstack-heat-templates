openstack overcloud deploy --templates \
	-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
	-e ~/templates/network-environment.yaml \
	-e ~/templates/firstboot-environment.yaml \
	--control-scale 1 \
	--compute-scale 1 \
	--control-flavor control \
	--compute-flavor compute \
	--ntp-server pool.ntp.org \
	--neutron-network-type vxlan \
	--neutron-tunnel-types vxlan

