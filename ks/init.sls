fzf:
  pkg.installed
unzip:
  pkg.installed
/opt/ks/dictionaries/:
  file.recurse:
    - makedirs: True
    - source: "salt://ks/dictionaries/"
/usr/local/bin/ks:
  file.managed:
    - source: "salt://ks/ks"
    - mode: "0755"