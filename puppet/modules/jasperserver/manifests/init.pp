class jasperserver () {

    exec {"get_jasperserver":
        command     => "/usr/bin/wget /tmp/jasperserver-4.7.0.zip http://nchc.dl.sourceforge.net/project/jasperserver/JasperServer/JasperReports%20Server%204.7.0/jasperreports-server-cp-4.7.0-bin.zip",
        timeout     => 0,
        provider    => "shell",
        onlyif      => "test ! -f /tmp/jasperserver-4.7.0.zip"
    }

    file { "${jasperHome}":
        ensure      => "directory",
        purge       => true,
        owner       => "${motechUser}",
        group       => "${motechUser}"
    }

    exec { "unzip_jasperserver":
        command     => "jar xvf /tmp/jasperserver-4.7.0.zip && cp -r ./jasperreports-server-cp-4.7.0-bin/* ./ && rm -rf ./jasperreports-server-cp-4.7.0-bin/",
        cwd         => "${jasperHome}",
        require     => [File["${jasperHome}"], Exec["get_jasperserver"]],
        provider    => "shell",
        user        => "${motechUser}"
    }

    file { "${jasperHome}/buildomatic/default_master.properties":
        content     => template("jasperserver/default_master.properties.erb"),
        require     => Exec['unzip_jasperserver'],
        owner       => "${motechUser}",
        group       => "${motechUser}"
    }

    file { "${jasperHome}/buildomatic/bin/do-js-setup.sh":
        content     => template("jasperserver/do-js-setup.sh"),
        require     => Exec['unzip_jasperserver'],
        owner       => "${motechUser}",
        group       => "${motechUser}"
    }

    exec { "set_jasperserver_scripts_permission":
        command     => "find . -name '*.sh' | xargs chmod u+x",
        user        => "${motechUser}",
        require     => [File["${jasperHome}/buildomatic/bin/do-js-setup.sh"], File["${jasperHome}/buildomatic/default_master.properties"]],
        cwd         => "${jasperHome}"
    }

    exec { "make_jasperserver":
        command     => "echo '$jasperResetDb' | /bin/sh ${jasperHome}/buildomatic/js-install-ce.sh minimal",
        require     => Exec["set_jasperserver_scripts_permission"],
        cwd         => "${jasperHome}/buildomatic",
        user        => "${motechUser}"
    }

    file { "/tmp/configure_jasper_home.sh" :
         require => Exec["make_jasperserver"],
         content => template("jasperserver/configure_jasper_home.sh"),
         owner => "${motechUser}",
         group => "${motechUser}",
         mode   =>  764
    }

    exec { "config-jasper-home" :
        require => File["/tmp/configure_jasper_home.sh"],
        command => "sh /tmp/configure_jasper_home.sh ${jasperHome} ${motechUser}",
        user        => "${motechUser}"
    }
}