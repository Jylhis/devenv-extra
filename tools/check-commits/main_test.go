package main

import (
	"slices"
	"strings"
	"testing"
)

func TestCheckSubject(t *testing.T) {
	tests := []struct {
		subject, body string
		want          []string // substrings, one per expected problem
	}{
		{"feat(languages): add haxe", "Why.", nil},
		{"docs: add README", "", nil},
		{"ci!: drop old job", "", nil},
		{"feat(a/b,c.d): x", "body", nil},
		{"feat: add thing", "", []string{"no body"}},
		{"fix: thing", "  \n", []string{"no body"}},
		{"Add haxe", "", []string{"not a Conventional Commit"}},
		{"feat(Lang): add", "b", []string{"not a Conventional Commit"}},
		{"docs: done.", "", []string{"period"}},
		{"docs: " + strings.Repeat("x", 70), "", []string{"over 72"}},
	}
	for _, tt := range tests {
		got := checkSubject(tt.subject, tt.body)
		if len(got) != len(tt.want) {
			t.Errorf("checkSubject(%q) = %q, want %d problems", tt.subject, got, len(tt.want))
			continue
		}
		for i, w := range tt.want {
			if !strings.Contains(got[i], w) {
				t.Errorf("checkSubject(%q)[%d] = %q, want it to contain %q", tt.subject, i, got[i], w)
			}
		}
	}
}

var modules = map[string]bool{"haxe": true, "cloudflare": true}

func TestClassifyPath(t *testing.T) {
	tests := map[string]string{
		"src/modules/languages/haxe.nix":                   "haxe",
		"src/modules/languages/new.nix":                    "new",
		"src/modules/integrations/cloudflare.nix":          "cloudflare",
		"haxe/devenv.nix":                                  "haxe",
		"tests/haxe/eval.nix":                              "haxe",
		"examples/cloudflare/devenv.yaml":                  "cloudflare",
		"docs/src/individual-docs/languages/haxe.md":       "haxe",
		"docs/src/content/docs/integrations/cloudflare.md": "cloudflare",
		"docs/src/index.md":                                "",
		"checks/default.nix":                               "",
		"tests/other/eval.nix":                             "",
		"flake.nix":                                        "",
		"haxe":                                             "",
		".github/workflows/check.yml":                      "",
	}
	for p, want := range tests {
		if got := classifyPath(p, modules); got != want {
			t.Errorf("classifyPath(%q) = %q, want %q", p, got, want)
		}
	}
}

func TestCheckScope(t *testing.T) {
	tests := []struct {
		name  string
		files []string
		want  int
	}{
		{"one module", []string{"src/modules/languages/haxe.nix", "tests/haxe/eval.nix"}, 0},
		{"shared only", []string{"checks/default.nix", "AGENTS.md"}, 0},
		{"two modules", []string{"haxe/devenv.nix", "cloudflare/devenv.nix"}, 1},
		{"module and shared", []string{"tests/haxe/eval.nix", "checks/stub.nix"}, 1},
		{"both", []string{"haxe/devenv.nix", "cloudflare/devenv.nix", "flake.nix"}, 2},
	}
	for _, tt := range tests {
		if got := checkScope(tt.files, modules); len(got) != tt.want {
			t.Errorf("%s: checkScope = %q, want %d problems", tt.name, got, tt.want)
		}
	}
}

func TestLines(t *testing.T) {
	if got := lines("a\nb\n\n"); !slices.Equal(got, []string{"a", "b"}) {
		t.Errorf("lines = %q", got)
	}
}
