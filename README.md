
# Miniproject
Dev enviroment created with salt

Tämän modulin tarkoitus on luoda käyttäjälle kehitysympäristön johon on asenettu Django kehitysympäristön ja tarvittavat apuohjelmat (Visual Studio Basic).

Tämän modulin tarkoitus on luoda käyttäjälle valmis työasema jossa hän voin työskenellä ja tarvittavat työkalut ovat saatavilla.

Modulin loppuasetelma:

Linux koneille:

 - Apache2 webbipalvelin jossa on mahdollistettu käyttäjien kotihakemisto kehitystä varten
 - Tarvittavia työkaluja (visual Studio code)
 - Micro
- Offline työskentelyyn Tero karvisen KanaSirja (ohjelma jolla voidaan selata eri ohjelmien dokumentaatiota)

Windows koneille:
 - Micron asennus
 - Visual studio code asennus
 - Chocolatey paketin hallinta ohjelma


Asennus toteutuu top.sls tiedoston kanssa. 

Kun käyttäjä asentaa hänen pitää asettaa Salt-minion id joko f* tai w' alkuiseksi.

Top tiedoston avulla ylläpitäjä voi suoraan asentaa ohjelmia kaikille windows sekä linux koneille. 
Modulia voi käyttää jos SALT-stack on konfiguroitu.
Artikkelista löytyy ohjeet arkitehtuurin alustamiseksi: https://terokarvinen.com/2023/salt-vagrant/

Modulin voi ottaa käyttöön kloonamalla repository herra koneelle ja siirtää kaikki tiedostot pl. lisenssi ja readme.md tiedosto `srv/salt` kansioon.

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
        
Yritin asentaa pkg.installed mutta törmäsin jatkuvasti ongelmiin.

Init.sls tiedostoni näytti tältä:

        /local/apt/repository/vscode:
         file.managed:
            - source: 'salt://vbslinux/code_1.78.0-1683145611_amd64.deb'
             - makedirs: 'True'
         vscode:
           pkg.installed:
            - name: "/local/apt/repository/code_1.78.0-1683145611_amd64.deb" 

        vagrant@fmaster:/srv/salt/vbslinux$ sudo salt 'f001' state.apply 'vbslinux'
        f001:
        ----------
                ID: /local/apt/repository/code_1.78.0-1683145611_amd64.deb
            Function: file.managed
            Result: True
            Comment: File /local/apt/repository/code_1.78.0-1683145611_amd64.deb is in the correct state
            Started: 19:01:12.861970
            Duration: 888.412 ms
            Changes:
        ----------
                ID: vscode
            Function: pkg.installed
            Result: False
            Comment: The following packages failed to install/update: /local/apt/repository/code_1.78.0-1683145611_amd64.deb
            Started: 19:01:14.408317
            Duration: 2163.503 ms
            Changes:

        Summary for f001
        ------------
        Succeeded: 1
        Failed:    1
        ------------
En vaan osannut löytää vastausta tähän. Joten päädyin käyttämään cmd.run komentoa.

Init tiedosto:

                /local/apt/repository/code_1.78.0-1683145611_amd64.deb:
                  file.managed:
                    - source: "salt://vbslinux/code_1.78.0-1683145611_amd64.deb"
                    - makedirs: True
                vscode:
                  cmd.run:
                    - name: "apt-get install -y /local/apt/repository/code_1.78.0-1683145611_amd64.deb"

Tällä sain toimimaan.
Lopputulos: 
![image](https://github.com/FredrikAkerlund/Miniproject/assets/122887178/ed8dd155-ba34-4a5b-894b-e18ca1c10c2e)


### Apachen asennus
Tässä huomiona että tein apachen asennusta pitkään ja törmäsin useaan ongelmaan mutta menetin kaiken raportointi työni kesken raportointia. Joten näytän miltä init.sls tiedostoni näyttää lopussa ja yritän muistaa mitä vaiheta työskentelyssä tapahtui.

                apache_module:
                  pkg.installed:
                    - names:
                      - "apache2"
                      - "curl"
                    - refresh: True


                enableuserdir:
                  cmd.run:
                    - name: "a2enmod userdir"

                defaultfrontpage:
                  file.managed:
                    - name: "/var/www/html/index.html"
                    - source: "salt://apache/index.html"
                    - makedirs: True
                apache2:
                  service.running:
                    - name: "apache2"
                    - watch:
                      - file: "/var/www/html/index.html"
                    - enable: True
                    - reload: True
                    
Kun minulla on nyt toimiva moduli näytän lopputuloksen.
![image](https://github.com/FredrikAkerlund/Miniproject/assets/122887178/583e7b88-3d0f-443a-9517-b39e98f7b207)

Valitettavasti tästä työstö vaiheesta jäi monta hyvää opetuspistettä raportoimasta.

Loppujen lopuksi en päässyt kokonaan haluaamaani lopputulokseen mutta jouduin taas jälleen kerran käyttämään cmd.run komentoa.

### Micro for windows and Linux

Olen aikasemmin ladannut asennustiedostot Microlle. Sekä linux Debian sekä Windows 10.

Lähde: https://github.com/zyedidia/micro/releases

Aloitan asentamalla käsin linuxille. Aika yksinkertaista:

        vagrant@fmaster:~$ sudo apt install micro
        vagrant@fmaster:~$ micro --version
        Version: 2.0.8

Kuten oletinkin se toimii!

Ja kyseessä on yksinkertainen init.sls tiedosto:

        micro:
        pkg.installed:
            - name: "micro"

Ja homma rockaa! Alan jo päästä tietojen menettämisen tuskasta.                
        
Totean nopeasti että helpoin tapa asentaa windowsille micro on luoda se idempotentti tilalla. 


Windowsilla siirrän .exe tiedoston `C://windows/system32` kansioon.

Totean nopeasti että helpoin tapa on luoda suoraan idempotentti tila sitä varte
           
        microforwin:
        file.managed:
            - name: "C:\Windows\System32\micro.exe"
            - source: "salt://microwin/micro"

Lopputulos:

![image](https://github.com/FredrikAkerlund/Miniproject/assets/122887178/17ec6516-de05-401c-9fef-b04b018dd5c0)


### Dokumentaatiota offline käyttöön (linuzx):

Tavoitteena on ladata linux koneille offline dokumentaatiota Offline työskentelyyn. Ohjelmana käytän Tero Karvisen KanaSirja ohjelmaa.
Lähde: https://terokarvinen.com/2022/ks-kanasirja-offline-tui-dictionary/

Ohjelman käyttämiseen tarvitsen: 
 - KS ohjelman (https://terokarvinen.com/2022/ks-kanasirja-offline-tui-dictionary/ks)
 - Offline kirjastot: (https://terokarvinen.com/ks-dict/)
 - FZF ja UNZIP ohjelman (virallisesta paketinhallinasta)

 Käytän avukseni terokarvisen artikkelia aiheesta 
 lähde: https://terokarvinen.com/2022/ks-kanasirja-offline-tui-dictionary/#quickstart

    wget https://terokarvinen.com/2022/ks-kanasirja-offline-tui-dictionary/ks
    chmod a+x ks
Tällä komenolla ladataan sanakirjastot

        $ mkdir $HOME/.config/ks/dictionaries/; cd $HOME/.config/ks/dictionaries/
        $ wget --continue -nd -np -r -l1 -A '*.zip' https://terokarvinen.com/ks-dict/
Näillä komenoilla ladataan kirjastot kansioon `/home/.config/ks/dictionaries/` jonka jälkeen ne puretaan.

Lopputulos: 

![image](https://github.com/FredrikAkerlund/Miniproject/assets/122887178/e3c4462d-f82d-4daa-b013-04305ebcccee)

Ensimmäiseksi siirrän kaikki tiedostot (ks binääri + kirjastot) `/srv/salt/ks` kansioon
Seuraavaksi luon init.sls tiedoston: 

                fzf:
                  pkg.installed
                unzip:
                  pkg.installed
             ## Luodaan kansio missä kirjastot on
                /opt/ks/dictionaries/:
                  file.recurse:
                    - makedirs: True
                    - source: "salt://ks/dictionaries/"
             ## Siirretään binääri tiedosto oikeaan kansioon  
               /usr/local/bin/ks:
                  file.managed:
                    - source: "salt://ks/ks"
                    - mode: "0755"

Lopputulos: 

                vagrant@fmaster:/srv/salt/ks/dictionaries$ sudo salt 'f003' state.apply 'ks'
                f003:
                ----------
                          ID: fzf
                    Function: pkg.installed
                      Result: True
                     Comment: All specified packages are already installed
                     Started: 20:24:05.826272
                    Duration: 43.858 ms
                     Changes:
                ----------
                          ID: unzip
                    Function: pkg.installed
                      Result: True
                     Comment: All specified packages are already installed
                     Started: 20:24:05.870279
                    Duration: 6.208 ms
                     Changes:
                ----------
                          ID: /opt/ks/dictionaries/
                    Function: file.recurse
                      Result: True
                     Comment: The directory /opt/ks/dictionaries/ is in the correct state
                     Started: 20:24:05.878238
                    Duration: 799.41 ms
                     Changes:
                ----------
                          ID: /usr/local/bin/ks
                    Function: file.managed
                      Result: True
                     Comment: File /usr/local/bin/ks is in the correct state
                     Started: 20:24:06.677741
                    Duration: 10.814 ms
                     Changes:

                Summary for f003
                ------------
                Succeeded: 4
                Failed:    0
                ------------
                Total states run:     4
                Total run time: 860.290 ms          


"Too easy"

Homma on rock!

Git alkoi temppuilemaan ja jostain syystä en pysty lisäämään source githubiin.

### TOPPI tiedoston luominen.

Luon top tiedoston joka automaattisesti ajaa kaikki komennot tarvitsijoille.

Tämä top tiedosto toimii siten että SALT orjien nimet pitää alkaa joko `f` = linux ja `w`=windows.

Tällä tiedostolla herra pystyy käskemään kaikki koneet tarvittavin osin configuroitavaksi.













