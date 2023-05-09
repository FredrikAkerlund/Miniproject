# Alpha versio
# Miniproject
Dev enviroment created with salt

Tämän modulin tarkoitus on luoda käyttäjälle kehitysympäristön johon on asenettu Django kehitysympäristön ja tarvittavat apuohjelmat (Visual Studio Basic).

Tämän modulin tarkoitus on luoda käyttäjälle valmis työasema jossa hän voin työskenellä ja tarvittavat työkalut ovat saatavilla.


## Alustus

Aloitan työskentelyn poistamalla kaikki vanhat virtuaalikoneet mitä loin kurssin aikana Vagrant:illa komenolla `vagrant destroy`.

Vagrant konfiguraatio tiedosto (lähde: https://terokarvinen.com/2023/salt-vagrant/): 

        # -*- mode: ruby -*-
        # vi: set ft=ruby :
        # Copyright 2014-2023 Tero Karvinen http://TeroKarvinen.com

        $minion = <<MINION
        sudo apt-get update
        sudo apt-get -qy install salt-minion
        echo "master: 192.168.12.3">/etc/salt/minion
        sudo service salt-minion restart
        echo "See also: https://terokarvinen.com/2023/salt-vagrant/"
        MINION

        $master = <<MASTER
        sudo apt-get update
        sudo apt-get -qy install salt-master
        echo "See also: https://terokarvinen.com/2023/salt-vagrant/"
        MASTER

        Vagrant.configure("2") do |config|
            config.vm.box = "debian/bullseye64"

            config.vm.define "f001" do |f001|
                f001.vm.provision :shell, inline: $minion
                f001.vm.network "private_network", ip: "192.168.12.100"
                f001.vm.hostname = "f001"
            end

            config.vm.define "f002" do |f002|
                f002.vm.provision :shell, inline: $minion
                f002.vm.network "private_network", ip: "192.168.12.102"
                f002.vm.hostname = "f002"
            end

            config.vm.define "fmaster", primary: true do |fmaster|
                fmaster.vm.provision :shell, inline: $master
                fmaster.vm.network "private_network", ip: "192.168.12.3"
                fmaster.vm.hostname = "fmaster"
            end
        end

Aiemmin minulla on asenettu windows virtuaalikone. Lähde: https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/

Yhteensä minulla on 3 orja konetta (2 Debian, 1 Windows) ja yksi herra kone.

        vagrant@fmaster:/srv/salt/apache$ sudo salt '*' test.ping
        f002:
            True
        f001:
            True
        windowslave:
            True


## Visual studio basic
Aloitan asentamalla Visual studio basic windows koneelle.

Otan käyttöön herra koneella Windows paketinhallinnan.

Lähde: https://terokarvinen.com/2018/control-windows-with-salt/

        $ sudo salt-run winrepo.update_git_repos
        $ sudo salt -G 'os:windows' pkg.refresh_db

Tämä ottaa käyttöön winrepot josta pystyn helposti asentamaan tiettyjä ohjelmia windows koneelle linux herra koneelta.

Lisäksi asennan windowsille paketinhallinnan `chocolatey` helpottaaksen ohjelmien asennusta.

        /srv/salt/apache$ sudo salt 'windowslave' pkg.install 'chocolatey'
        windowslave:
            ----------
            chocolatey:
                ----------
                new:
                    1.3.1
                old:

Seuraavaksi kokeilen suoraan asentaa VScode

    vagrant@fmaster:/srv/salt/apache$ sudo salt 'windowslave' chocolatey.install vscode

Linuxilla asennan myös visual studio coden. Tämä asennetaan .deb paketista.
.deb paketti lähde: https://code.visualstudio.com/docs/?dv=linux64_deb

Eka teen käsin:
        sudo apt-get install /home/vagrant/Miniproject/VBS/code_1.78.0-1683145611_amd64.deb -y
        vagrant@fmaster:~/Miniproject/VBS$ code --version
        1.78.0
        252e5463d60e63238250799aef7375787f68b4ee
        x64

Tästä näen että uusin VScode on asenettu. En pääse vagrantkoneen työpäydälle jostain syystä. Työpöytä ei  taida olla asenettuna.

Seuraavaksi teen asennuksista idempotentin.

Aloitan luomalla `vbswin` tilan:

Kansioon `/srv/salt/vbswin` luon init.sls tiedoston: 

        chocolatey:
          pkg.installed
        choco:
          chocolatey.installed:
            - name: 'vscode'

Tämä tila asentaa chocolatey paketinhallinnan sekä `visualstudiocode` ohjelmiston:

Lopputulos: 

                windowslave:
        ----------
                ID: chocolatey
            Function: pkg.installed
            Result: True
            Comment: All specified packages are already installed
            Started: 10:32:01.982323
            Duration: 287.23 ms
            Changes:
        ----------
                ID: choco
            Function: chocolatey.installed
                Name: vscode
            Result: True
            Comment: vscode 1.78.0 is already installed
            Started: 10:32:02.269553
            Duration: 2876.952 ms
            Changes:

        Summary for windowslave
        ------------
        Succeeded: 2
        Failed:    0

Kuvanruutukaappaus: WINKKARISTA:



Seuraavaksi teen `vbslinux` tilan:

Kansioon `/srv/salt/vbslinux` luon init.sls tiedoston:
        
        /local/apt/repository/vscode:
        file.managed:
            - source: 'salt://vbslinux/code_1.78.0-1683145611_amd64.deb'
            - makedirs: 'True'
        vscode:
        cmd.run:
            - name: "apt-get install -y /local/apt/repository/code_1.78.0-1683145611_amd64.deb" 

Tila luo kansioon: `/local/apt/repository/` .deb tiedoston josta paketti asennetaan.

        Lopputulos: 
        vagrant@fmaster:/srv/salt/vbslinux$ sudo salt 'f001' state.apply 'vbslinux'
        f001:
        ----------
                ID: /local/apt/repository/code_1.78.0-1683145611_amd64.deb
            Function: file.managed
            Result: True
            Comment: File /local/apt/repository/code_1.78.0-1683145611_amd64.deb is in the correct state
            Started: 19:06:20.870698
            Duration: 606.534 ms
            Changes:
        ----------
                ID: vscode
            Function: cmd.run
                Name: apt-get install -y /local/apt/repository/code_1.78.0-1683145611_amd64.deb
            Result: True
            Comment: Command "apt-get install -y /local/apt/repository/code_1.78.0-1683145611_amd64.deb" run
            Started: 19:06:21.477876
            Duration: 503.56 ms
            Changes:
                    ----------
                    pid:
                        16902
                    retcode:
                        0
                    stderr:
                    stdout:
                        Reading package lists...
                        Building dependency tree...
                        Reading state information...
                        code is already the newest version (1.78.0-1683145611).
                        0 upgraded, 0 newly installed, 0 to remove and 34 not upgraded.

        Summary for f001
        ------------
        Succeeded: 2 (changed=1)
        Failed:    0
        ------------
        Total states run:     2
        Total run time:   1.110 s
        



### Apachen asennus

### SSH konfigurointi

### PostSQL konfigurointi
### Apache
### Django kehitysympäristö
- UFW Tarvittavat portit auki
### Windows koneet

### Visual Studio Basic

### Tarvittavat Dokumentaatiot OFFLINE työskentelyyn





