class phpmyadmin(
      $install_location = '/var/www/html/phpMyAdmin'
   ) {
   exec {
      'install-phpmyadmin':
         path    => '/bin/:/usr/bin',
         command => "curl -SsL https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.tar.gz | tar xzfv - && mv -i phpmyadmin-STABLE $install_location",
         creates => $install_location,
         cwd     => '/tmp';
      'install-phpmyadmin-db':
         path    => '/bin/:/usr/bin',
         command => "cat $install_location/examples/create_tables.sql | mysql -u root",
         unless  => 'test `mysql phpmyadmin -NBe \'SHOW TABLES\' | wc -l` -gt 0',
         require => [ Exec['install-phpmyadmin'], Mysql_database['phpmyadmin'] ];
   }

   file {
      '/var/www/html/phpMyAdmin/config.inc.php':
         ensure  => present,
         source  => "puppet:///modules/phpmyadmin/config.inc.php",
         owner   => 'root',
         group   => 'root',
         mode    => 0644,
         require => Exec['install-phpmyadmin'];
   }

   mysql_database {
      'phpmyadmin':
         ensure   => 'present',
         charset  => 'utf8',
         collate  => 'utf8_bin',
         require  => [Package['mysql_client', 'mysql-server'], Service['mysqld']];
   }

   mysql_user {
      'pma@127.0.0.1':
         ensure   => 'present',
         password => '',
         require  => [Package['mysql_client', 'mysql-server'], Service['mysqld']];
   }

   mysql_grant {
      'pma@127.0.0.1/phpmyadmin.*':
         ensure     => 'present',
         options    => ['GRANT'],
         privileges => ['ALL'],
         table      => 'phpmyadmin.*',
         user       => 'pma@127.0.0.1',
         require    => [Package['mysql_client', 'mysql-server'], Service['mysqld']];
   }
}