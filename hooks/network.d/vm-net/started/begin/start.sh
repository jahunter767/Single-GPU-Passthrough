#! /bin/bash

# To extend the functionality of the default hooks you can either redefine
# some of the functions in the default scripts in scripts in this folder
# or uncomment the function below and add extra commands before or after the
# call of the main function (main is defined in the 99-main.sh script located
# default folder on a similar path)
#
# You can also override default variables declared in hooks/default.d/network
# by specifying a new assignment here (outside of the function).
# (Note: remember to maintain the same variable type).

function started_begin {
    # <your code here>
    main
    # <your code here>
    execute "setsebool samba_enable_home_dirs on"
    #execute "setsebool samba_export_all_rw on"
    execute "setsebool nis_enabled on"
    execute "systemctl start nfs-server.service sshd.service smb.service nmb.service"
} # End-started_begin
