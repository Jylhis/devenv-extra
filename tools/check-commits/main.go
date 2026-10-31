// Command check-commits checks the commits in a git range against the rules in
// CONTRIBUTING.md: Conventional Commits subjects, and at most one module per
// commit, never mixed with shared infrastructure.
//
// Usage: check-commits <revision range>
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"regexp"
	"slices"
	"strings"
)

const maxSubject = 72

var subjectRe = regexp.MustCompile(
	`^(feat|fix|docs|test|tests|refactor|chore|ci|perf|build|style|revert)` +
		`(\([a-z0-9.,/-]+\))?!?: \S.*`)

type commit struct {
	sha, subject, body string
}

// checkSubject returns the problems with a commit's subject and body.
func checkSubject(subject, body string) []string {
	var problems []string
	m := subjectRe.FindStringSubmatch(subject)
	if m == nil {
		problems = append(problems, "subject is not a Conventional Commit: type(scope): summary")
	}
	if n := len([]rune(subject)); n > maxSubject {
		problems = append(problems, fmt.Sprintf("subject is %d characters, over %d", n, maxSubject))
	}
	if strings.HasSuffix(subject, ".") {
		problems = append(problems, "subject ends with a period")
	}
	if m != nil && (m[1] == "feat" || m[1] == "fix") && strings.TrimSpace(body) == "" {
		problems = append(problems, m[1]+" commit has no body saying why")
	}
	return problems
}

// moduleFile returns the module name for src/modules/<kind>/<name>.nix.
func moduleFile(p string) (string, bool) {
	parts := strings.Split(p, "/")
	if len(parts) == 4 && parts[0] == "src" && parts[1] == "modules" && strings.HasSuffix(parts[3], ".nix") {
		return strings.TrimSuffix(parts[3], ".nix"), true
	}
	return "", false
}

// classifyPath returns the module a path belongs to, or "" for shared infrastructure.
func classifyPath(p string, modules map[string]bool) string {
	if name, ok := moduleFile(p); ok {
		return name
	}
	parts := strings.Split(p, "/")
	var candidate string
	switch {
	case len(parts) >= 3 && (parts[0] == "tests" || parts[0] == "examples"):
		candidate = parts[1]
	case parts[0] == "docs" && path.Ext(p) == ".md":
		candidate = strings.TrimSuffix(path.Base(p), ".md")
	case len(parts) >= 2:
		candidate = parts[0]
	}
	if modules[candidate] {
		return candidate
	}
	return ""
}

// checkScope returns the problems with the set of files one commit touches.
func checkScope(files []string, modules map[string]bool) []string {
	var touched, shared []string
	for _, f := range files {
		if m := classifyPath(f, modules); m == "" {
			shared = append(shared, f)
		} else if !slices.Contains(touched, m) {
			touched = append(touched, m)
		}
	}
	var problems []string
	if len(touched) > 1 {
		problems = append(problems, "touches more than one module: "+strings.Join(touched, ", "))
	}
	if len(touched) > 0 && len(shared) > 0 {
		problems = append(problems, fmt.Sprintf("mixes module %s with shared files: %s",
			strings.Join(touched, ", "), strings.Join(shared, ", ")))
	}
	return problems
}

func git(args ...string) (string, error) {
	out, err := exec.Command("git", args...).Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return string(out), nil
}

func lines(s string) []string {
	return strings.FieldsFunc(s, func(r rune) bool { return r == '\n' })
}

func commits(revRange string) ([]commit, error) {
	out, err := git("log", "--no-merges", "--format=%H%x00%s%x00%b%x1e", revRange)
	if err != nil {
		return nil, err
	}
	var cs []commit
	for rec := range strings.SplitSeq(out, "\x1e") {
		fields := strings.SplitN(strings.TrimLeft(rec, "\n"), "\x00", 3)
		if len(fields) == 3 {
			cs = append(cs, commit{sha: fields[0], subject: fields[1], body: fields[2]})
		}
	}
	return cs, nil
}

// checkCommit returns every problem with one commit.
func checkCommit(c commit) ([]string, error) {
	files, err := git("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", c.sha)
	if err != nil {
		return nil, err
	}
	tree, err := git("ls-tree", "-r", "--name-only", c.sha, "--", "src/modules")
	if err != nil {
		return nil, err
	}
	// Modules in the commit's tree, plus any it deletes.
	modules := map[string]bool{}
	for _, f := range append(lines(tree), lines(files)...) {
		if name, ok := moduleFile(f); ok {
			modules[name] = true
		}
	}
	return append(checkSubject(c.subject, c.body), checkScope(lines(files), modules)...), nil
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: check-commits <revision range>")
		os.Exit(2)
	}
	cs, err := commits(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	failed := false
	for _, c := range cs {
		problems, err := checkCommit(c)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(2)
		}
		for _, p := range problems {
			fmt.Printf("%.7s %s: %s\n", c.sha, c.subject, p)
			failed = true
		}
	}
	if failed {
		os.Exit(1)
	}
	fmt.Printf("%d commits ok\n", len(cs))
}
