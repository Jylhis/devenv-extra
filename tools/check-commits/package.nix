# The commit checker; buildGoModule runs main_test.go in checkPhase.
{
  lib,
  buildGoModule,
  makeWrapper,
  git,
}:
buildGoModule {
  pname = "check-commits";
  version = "0.1.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "go" || f.name == "go.mod") ./.;
  };
  vendorHash = null;
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/check-commits --prefix PATH : ${lib.makeBinPath [ git ]}
  '';
  meta = {
    description = "Check commit subjects and per-commit module scope";
    mainProgram = "check-commits";
  };
}
