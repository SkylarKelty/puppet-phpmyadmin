class phpmyadmin (
      $install_location = '/var/www/html/phpMyAdmin'
   ) {

   exec {
      'install-phpmyadmin':
         path    => '/bin/:/usr/bin',
         command => "curl -SsL https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.tar.gz | tar xzf - && mv phpmyadmin-STABLE/* $install_location/",
         creates => "$install_location/index.php",
         cwd     => '/tmp',
         require => File[$install_location];
      'install-phpmyadmin-db':
         path    => '/bin/:/usr/bin',
         command => "mysql -u pma --password=password < $install_location/examples/create_tables.sql",
         unless  => 'test `mysql phpmyadmin -u pma --password=password -NBe \'SHOW TABLES\' | wc -l` -gt 0',
         require => [ Exec['install-phpmyadmin'], Mysql_database['phpmyadmin'], Mysql_user['pma@localhost'], Mysql_grant['pma@localhost/phpmyadmin.*'] ];
   }

   file {
      $install_location:
         ensure  => directory;
      "$install_location/config.inc.php":
         ensure  => present,
         source  => "puppet:///modules/phpmyadmin/config.inc.php",
         owner   => 'root',
         group   => 'root',
         mode    => 0644,
         require => Exec['install-phpmyadmin'];
      '/etc/php5/apache2/conf.d/20-phpmyadmin.ini':
         ensure  => present,
         source  => 'puppet:///modules/phpmyadmin/php.ini',
         notify  => Service['apache2'];
   }

   mysql_database {
      'phpmyadmin':
         ensure   => 'present',
         charset  => 'utf8',
         collate  => 'utf8_bin';
   }

   mysql_user {
      'pma@localhost':
         password_hash => '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19',
         ensure   => 'present';
   }

   mysql_grant {
      'pma@localhost/phpmyadmin.*':
         ensure     => 'present',
         options    => ['GRANT'],
         privileges => ['ALL'],
         table      => 'phpmyadmin.*',
         user       => 'pma@localhost';
   }
}