apache_MOD:
  pkg.installed:
    - name: "apache2"
    - name: "libapache2-mod-userdir"
apache2:
  service.running:
    - watch:
      - file "/etc/apache2/sites-available/frontpage.conf"
      -pkg: "mod_userdir"
/etc/apache2/sites-available/frontpage.conf:
  file.managed:
    - source: "salt://apache/frontpage.conf"
apache_user_directories:
  file.directory:
    - name: /var/www/html/users
    - user: www-data
    - group: www-data
    - dir_mode: 755
{% for user in salt['user.list_users']() %}
apache_user_directory_{{ user }}:
  file.directory:
    - name: /var/www/html/users/{{ user }}/public_html
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 755
{% endfor %}