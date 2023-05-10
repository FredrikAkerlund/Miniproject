apache_module:
  pkg.installed:
    - name: "apache2"
    - name: "curl"
    - refresh: True


enableuserdir:
  file.managed:
    - name: "/etc/apache2/mods-enabled/userdir.conf"
    - source: "salt://apache/userdir.conf"

defaultfrontpage:
  file.managed:
    - name: "/var/www/html/index.html"
    - source: "salt://apache/index.html"

apache2:
  service.running:
    - name: "apache2"
    - watch:
      - file: "/etc/apache2/mods-enabled/userdir.conf"
    - enable: True
