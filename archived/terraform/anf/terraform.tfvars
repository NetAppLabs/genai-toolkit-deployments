subscription = ""
resource_group_name = ""
location = ""
vnet = ""
subnetid = ""
admin_username = ""
admin_password = ""
admin_ssh_key_file_location = ""
source_ip_range = "*"

// List of volumes you want to mount the files from. Example variable:
// anf_volumes = [
//   "1.2.3.4:/volume1",
//   "5.6.7.8:/volume2"
// ]

anf_volumes = []
ontap_volumes = []
