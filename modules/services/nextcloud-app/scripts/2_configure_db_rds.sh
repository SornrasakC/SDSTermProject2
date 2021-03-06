#!/bin/bash

touch 2-0.txt

# RDS config
cat << EOF > nextcloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "${db_name}",
  "dbuser"        => "${db_user}",
  "dbpass"        => "${db_pass}",
  "dbhost"        => "${db_endpoint}",
  "dbtableprefix" => "",
  "adminlogin"    => "${admin_user}",
  "adminpass"     => "${admin_pass}",
  "directory"     => "${data_dir}",
);
EOF

touch 2-1.txt
