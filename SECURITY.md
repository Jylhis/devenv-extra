# Security policy

## Reporting a vulnerability

Report it privately through GitHub: on the repository's **Security** tab,
choose **Report a vulnerability**. Please don't open a public issue.

## Scope

In scope: the devenv modules, checks and CI workflows in this repository, for
example a module that exposes a service or a credential it shouldn't, or that
runs untrusted code when a project enables it.

A vulnerability in a tool a module installs belongs to that project. Packages
missing from nixpkgs come from
[nixpkgs-extra](https://github.com/Jylhis/nixpkgs-extra), which has its own
policy.

<!-- Assisted-by: Claude Code:claude-opus-5-5 -->
