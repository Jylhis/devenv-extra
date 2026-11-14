{
  languages.qml.enable = true;

  enterTest = ''
    command -v qmlls
    qmllint --version
    qmlformat --version
    test -n "$QML_IMPORT_PATH"
  '';
}
