/local/apt/repository/vscode:
  file.managed:
    - source: 'salt://vbslinux/code_1.78.0-1683145611_amd64.deb'
    - makedirs: 'True'
vscode:
  cmd.run:
    - name: "apt-get install -y /local/apt/repository/code_1.78.0-1683145611_amd64.deb"