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


