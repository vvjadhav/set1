https://docs.openstack.org/install-guide/openstack-services.html
https://docs.openstack.org/neutron/wallaby/admin/deploy-ovs-provider.html#east-west-scenario-1-instances-on-the-same-network
https://docs.openstack.org/neutron/wallaby/admin/deploy-ovs-provider.html#east-west-scenario-2-instances-on-different-networks
Identity service – keystone installation for Wallaby

Image service – glance installation for Wallaby

Placement service – placement installation for Wallaby

Compute service – nova installation for Wallaby

Networking service – neutron installation for Wallaby

We advise to also install the following components after you have installed the minimal deployment services:

Dashboard – horizon installation for Wallaby

Block Storage service – cinder installation for Wallaby

Centos8



yum config-manager --set-enabled PowerTools
yum install centos-release-openstack-Wallaby. # check this command
yum upgrade
yum install python3-openstackclient
yum install openstack-selinux


yum install mariadb mariadb-server python2-PyMySQL
/etc/my.cnf.d/openstack.cnf

[mysqld]
bind-address = 10.0.0.11

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8

->database
systemctl enable mariadb.service
systemctl start mariadb.service
mysql_secure_installation

->rabbitmq
yum install rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

rabbitmqctl add_user openstack RABBIT_PASS
o-> Creating user "openstack" ...

rabbitmqctl set_permissions openstack ".*" ".*" ".*"
o-> Setting permissions for user "openstack" in vhost "/" ...

->memcached
yum install memcached python3-memcached
/etc/sysconfig/memcached
OPTIONS="-l 127.0.0.1,::1,controller"

systemctl enable memcached.service
systemctl start memcached.service

->etcd
yum install etcd
/etc/etcd/etcd.conf.  # ETCD_INITIAL_CLUSTER, ETCD_INITIAL_ADVERTISE_PEER_URLS, ETCD_ADVERTISE_CLIENT_URLS, ETCD_LISTEN_CLIENT_URLS
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://10.0.0.11:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.0.0.11:2379"
ETCD_NAME="controller"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.11:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.11:2379"
ETCD_INITIAL_CLUSTER="controller=http://10.0.0.11:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"

systemctl enable etcd
systemctl start etcd

->keystone

mysql -u root -p
MariaDB [(none)]> CREATE DATABASE keystone;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';

yum install openstack-keystone httpd python3-mod_wsgi
/etc/keystone/keystone.conf
[database]
# ...
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
[token]
# ...
provider = fernet

su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

/etc/httpd/conf/httpd.conf
ServerName controller
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service

#Check identity service using keystone database
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

openstack domain create --description "An Example Domain" example
openstack project create --domain default \                             #create a new domain
  --description "Service Project" service       #Create the service project

openstack project create --domain default \
  --description "Demo Project" myproject        #Create the myproject project:

openstack user create --domain default \
  --password-prompt myuser                      #Create the myuser user

openstack role create myrole #Create the myrole role

openstack role add --project myproject --user myuser myrole #Add the myrole role to the myproject project and myuser user: #No output

unset OS_AUTH_URL OS_PASSWORD

openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue               # use admin password

openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name myproject --os-username myuser token issue          # use myuser password

vi admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

vi demo-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

. admin-openrc
openstack token issue




-> glance
mysql -u root -p
MariaDB [(none)]> CREATE DATABASE glance;

MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';

. admin-openrc

openstack user create --domain default --password-prompt glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
  
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292

yum install openstack-glance
/etc/glance/glance-api.conf

[database]
# ...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
[keystone_authtoken]                                                        #Comment out or remove any other options in the [keystone_authtoken] section.

# ...
www_authenticate_uri  = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
# ...
flavor = keystone

[glance_store]
# ...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

su -s /bin/sh -c "glance-manage db_sync" glance. # Ignore deprecation messsages

systemctl enable openstack-glance-api.service
systemctl start openstack-glance-api.service

. admin-openrc
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

glance image-create --name "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --visibility=public

glance image-list


->additional info on glance
https://docs.openstack.org/glance/wallaby/configuration/index.html
Basic Configuration
glance-api.conf
glance-cache.conf
glance-manage.conf
glance-scrubber.conf
Glance Sample Configuration -> https://docs.openstack.org/glance/wallaby/configuration/sample-configuration.html
https://docs.openstack.org/glance/wallaby/user/index.html


->placement
mysql -u root -p
MariaDB [(none)]> CREATE DATABASE placement;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';

  . admin-openrc
openstack user create --domain default --password-prompt placement
openstack role add --project service --user placement admin

openstack service create --name placement \
  --description "Placement API" placement
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778

openstack endpoint create --region RegionOne \
  placement admin http://controller:8778

yum install openstack-placement-api
/etc/placement/placement.conf

[placement_database]
# ...
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_PASS

su -s /bin/sh -c "placement-manage db sync" placement
systemctl restart httpd

. admin-openrc
placement-status upgrade check
pip3 install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name



->nova # https://docs.openstack.org/nova/wallaby/install/
#Controller node
mysql -u root -p

MariaDB [(none)]> CREATE DATABASE nova_api;
MariaDB [(none)]> CREATE DATABASE nova;
MariaDB [(none)]> CREATE DATABASE nova_cell0;

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

  . admin-openrc

openstack user create --domain default --password-prompt nova
openstack role add --project service --user nova admin

openstack service create --name nova \
  --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1

yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-novncproxy openstack-nova-scheduler

/etc/nova/nova.conf
[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata
[api_database]
# ...
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

[database]
# ...
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova
[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/

[api]
# ...
auth_strategy = keystone

#Comment out or remove any other options in the [keystone_authtoken] section.
[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[DEFAULT]
# ...
my_ip = 10.0.0.11

[vnc]
enabled = true
# ...
server_listen = $my_ip
server_proxyclient_address = $my_ip

[glance]
# ...
api_servers = http://controller:9292

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp

[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS

#Configure the [neutron] section of /etc/nova/nova.conf. Refer to the Networking service install guide for more details.

su -s /bin/sh -c "nova-manage api_db sync" nova #Ignore any deprecation messages in this output.
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova # Verify

systemctl enable \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service

systemctl start \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service


->nova # https://docs.openstack.org/nova/wallaby/install/compute-install-rdo.html
#Compute node

yum install openstack-nova-compute
/etc/nova/nova.conf

[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata

[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller

[api]
# ...
auth_strategy = keystone

#Comment out or remove any other options in the [keystone_authtoken] section.
[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[DEFAULT]
# ...
my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS
#Replace MANAGEMENT_INTERFACE_IP_ADDRESS with the IP address of the management network interface on your compute node, typically 10.0.0.31 for the first node in the example architecture.
#Configure the [neutron] section of /etc/nova/nova.conf. Refer to the Networking service install guide for more details.

[vnc]
# ...
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
# ...
api_servers = http://controller:9292

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp

[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS




egrep -c '(vmx|svm)' /proc/cpuinfo

/etc/nova/nova.conf

[libvirt]
# ...
virt_type = qemu

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

#If the nova-compute service fails to start, check /var/log/nova/nova-compute.log. The error message AMQP server on controller:5672 is unreachable likely indicates that the firewall on the controller node is preventing access to port 5672. Configure the firewall to open port 5672 on the controller node and restart nova-compute service on the compute node.

Run the following commands on the controller node.
. admin-openrc
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

When you add new compute nodes, you must run nova-manage cell_v2 discover_hosts on the controller node to register those new compute nodes. Alternatively, you can set an appropriate interval in /etc/nova/nova.conf:
[scheduler]
discover_hosts_in_cells_interval = 300

Verify operation of the Compute service.
. admin-openrc
openstack compute service list
openstack catalog list

openstack image list
nova-status upgrade check







->neutron
https://docs.openstack.org/neutron/wallaby/install/environment-networking-rdo.html

Controller node
Configure the first interface as the management interface:

IP address: 10.0.0.11
Network mask: 255.255.255.0 (or /24)
Default gateway: 10.0.0.1

The provider interface uses a special configuration without an IP address assigned to it. Configure the second interface as the provider interface:

Replace INTERFACE_NAME with the actual interface name. For example, eth1 or ens224.
Edit the /etc/sysconfig/network-scripts/ifcfg-INTERFACE_NAME file to contain the following:
Do not change the HWADDR and UUID keys.

DEVICE=INTERFACE_NAME
TYPE=Ethernet
ONBOOT="yes"
BOOTPROTO="none"
Reboot the system to activate the changes.

#Configure name resolution
Set the hostname of the node to controller.
Edit the /etc/hosts file to contain the following
# controller
10.0.0.11       controller

# compute1
10.0.0.31       compute1

# block1
10.0.0.41       block1

# object1
10.0.0.51       object1

# object2
10.0.0.52       object2

Some distributions add an extraneous entry in the /etc/hosts file that resolves the actual hostname to another loopback IP address such as 127.0.1.1. You must comment out or remove this entry to prevent name resolution problems. Do not remove the 127.0.0.1 entry.

Compute node
Configure the first interface as the management interface:

IP address: 10.0.0.31
Network mask: 255.255.255.0 (or /24)
Default gateway: 10.0.0.1

The provider interface uses a special configuration without an IP address assigned to it. Configure the second interface as the provider interface:

Replace INTERFACE_NAME with the actual interface name. For example, eth1 or ens224.
Edit the /etc/sysconfig/network-scripts/ifcfg-INTERFACE_NAME file to contain the following:
Do not change the HWADDR and UUID keys.

DEVICE=INTERFACE_NAME
TYPE=Ethernet
ONBOOT="yes"
BOOTPROTO="none"

Reboot the system to activate the changes.

Configure name resolution¶
Set the hostname of the node to compute1.

Edit the /etc/hosts file to contain the following:

# controller
10.0.0.11       controller

# compute1
10.0.0.31       compute1

# block1
10.0.0.41       block1

# object1
10.0.0.51       object1

# object2
10.0.0.52       object2
 Warning

Some distributions add an extraneous entry in the /etc/hosts file that resolves the actual hostname to another loopback IP address such as 127.0.1.1. You must comment out or remove this entry to prevent name resolution problems. Do not remove the 127.0.0.1 entry.

Verify connectivity
From the controller node, test access to the Internet:
ping -c 4 openstack.org

From the controller node, test access to the management interface on the compute node:
ping -c 4 compute1

From the compute node, test access to the Internet:
ping -c 4 openstack.org
From the compute node, test access to the management interface on the controller node:






Install and configure controller node
#https://docs.openstack.org/neutron/wallaby/install/controller-install-rdo.html
mysql -u root -p

MariaDB [(none)] CREATE DATABASE neutron;

MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';

. admin-openrc

openstack user create --domain default --password-prompt neutron

openstack role add --project service --user neutron admin

openstack service create --name neutron \
  --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
  network public http://controller:9696

  openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696




Configure Provider network
#https://docs.openstack.org/neutron/wallaby/install/controller-install-option1-rdo.html
https://docs.openstack.org/neutron/wallaby/install/ovn/manual_install.html

On the controller node

Install the components
yum install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables

/etc/neutron/neutron.conf
[database]
# ...
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
[DEFAULT]
# ...
core_plugin = ml2
service_plugins =

[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller

[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS


[DEFAULT]
# ...
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[nova]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp

Configure the Modular Layer 2 (ML2) plug-in¶
/etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
# ...
type_drivers = flat,vlan
[ml2]
# ...
tenant_network_types =

[ml2]
# ...
mechanism_drivers = linuxbridge

[ml2]
# ...
extension_drivers = port_security

[ml2_type_flat]
# ...
flat_networks = provider

[securitygroup]
# ...
enable_ipset = true





Configure the Linux bridge agent
/etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
#Replace PROVIDER_INTERFACE_NAME with the name of the underlying provider physical network interface. See Host networking for more information.

[vxlan]
enable_vxlan = false

[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

#Ensure your Linux operating system kernel supports network bridge filters by verifying all the following sysctl values are set to 1:
net.bridge.bridge-nf-call-iptables
net.bridge.bridge-nf-call-ip6tables





Configure the DHCP agent
/etc/neutron/dhcp_agent.ini
[DEFAULT]
# ...
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true


#Continue on the controller node with remaining config
/etc/neutron/metadata_agent.ini
[DEFAULT]
# ...
nova_metadata_host = controller
metadata_proxy_shared_secret = METADATA_SECRET. #Replace METADATA_SECRET with a suitable secret for the metadata proxy.

/etc/nova/nova.conf

[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET

#Finalize installation
The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini pointing to the ML2 plug-in configuration file, /etc/neutron/plugins/ml2/ml2_conf.ini. If this symbolic link does not exist, create it using the following command:

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service


 # Install and configure neutron on compute node
 yum install openstack-neutron-linuxbridge ebtables ipset



 /etc/neutron/neutron.conf
 [DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp

# Configure Option 1 - Provider Networks - Networking components on a compute node.
#https://docs.openstack.org/neutron/wallaby/install/compute-install-option1-rdo.html
/etc/neutron/plugins/ml2/linuxbridge_agent.ini 
[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
#Replace PROVIDER_INTERFACE_NAME with the name of the underlying provider physical network interface. See Host networking for more information.
[vxlan]
enable_vxlan = false
[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


#Ensure your Linux operating system kernel supports network bridge filters by verifying all the following sysctl values are set to 1:
net.bridge.bridge-nf-call-iptables
net.bridge.bridge-nf-call-ip6tables
#To enable networking bridge support, typically the br_netfilter kernel module needs to be loaded. Check your operating system’s documentation for additional details on enabling this module.

# Continue neutron configuration on compute node
/etc/nova/nova.conf
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS



systemctl restart openstack-nova-compute.service

systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

# OVN  https://docs.openstack.org/neutron/wallaby/install/ovn/index.html




->horizon
https://docs.openstack.org/horizon/wallaby/install/
#This section assumes proper installation, configuration, and operation of the Identity service using the Apache HTTP server and Memcached service.

Installation
#https://docs.openstack.org/horizon/wallaby/install/install-rdo.html
yum install openstack-dashboard

/etc/openstack-dashboard/local_settings
OPENSTACK_HOST = "controller"
ALLOWED_HOSTS = ['one.example.com', 'two.example.com'] #ALLOWED_HOSTS can also be [‘*’] to accept all hosts. This may be useful for development work, but is potentially insecure and should not be used in production. See https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts for further information.

Configure the memcached session storage service:
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}

OPENSTACK_KEYSTONE_URL = "http://%s/identity/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

#If you chose networking option 1, disable support for layer-3 networking services:
OPENSTACK_NEUTRON_NETWORK = {
    ...
    'enable_router': False,
    'enable_quotas': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_fip_topology_check': False,
}
Optionally, configure the time zone:
TIME_ZONE = "TIME_ZONE"





/etc/httpd/conf.d/openstack-dashboard.conf 
WSGIApplicationGroup %{GLOBAL}


systemctl restart httpd.service memcached.service

Verify operation of the dashboard.

Access the dashboard using a web browser at http://controller/dashboard.
Authenticate using admin or demo user and default domain credentials.


