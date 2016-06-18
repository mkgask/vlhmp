# Vagrant-Linux-h2o-MariaDB-PHP7

| type | value |
|------|-------|
| VirtualMachine | Vagrant |
| Supported OS | Ubuntu/Trusty or Debian/Jessie |
| | (If you want to use Ubuntu/Xenial, maybe same settings Debian/Jessie. Not yet confirmed) |
| front | h2o web server |
| app   | php7 |
| db    | MariaDB |


Usage:

1. Git clone this repository  
    ``` 
    git clone https://github.com/mkgask/Vagrant-Linux-h2o-MariaDB-PHP7.git  
    ```  
    (If the git repository is not required, the zip or tar.gz file download & unzip)

2. Check and changing environment yml file  
    itamae/roles/dev/env.yml

3. Vagrant up  
    ```
    vagrant up
    ```

4. itamae ssh  
    ```
    itamae ssh -h 192.168.33.10 -u vagrant --node-yaml=itamae/roles/dev/env.yml itamae/roles/dev/setup.rb
    ```

If h2o and php-fpm is not connected, restart the service h2o and php-fpm.

require [Itamae](https://github.com/itamae-kitchen/itamae) simple and lightweight configuration management tool.