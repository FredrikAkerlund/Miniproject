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

Eka teen käsin:

        

### Apachen asennus

### SSH konfigurointi

### PostSQL konfigurointi
### Apache
### Django kehitysympäristö
- UFW Tarvittavat portit auki
### Windows koneet

### Visual Studio Basic

### Tarvittavat Dokumentaatiot OFFLINE työskentelyyn





