// Copyright 2026 vfox-elixir contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//go:build !windows

package e2e

import (
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

// TestFakeUnixElixirRuns runs the bin/elixir of a fake installation. That checks
// the shebang, the executable bit and the banner together.
func TestFakeUnixElixirRuns(t *testing.T) {
	fake := newFakeInstall(t.TempDir(), "26")
	if err := writeFakeInstall(fake); err != nil {
		t.Fatalf("writeFakeInstall: %v", err)
	}

	program := filepath.Join(fake.root, "bin", "elixir")
	info, err := os.Stat(program)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm()&0o111 == 0 {
		t.Fatalf("%s is not executable: mode %v", program, info.Mode())
	}

	out, err := exec.Command(program, "--version").CombinedOutput()
	if err != nil {
		t.Fatalf("run %s: %v\n%s", program, err, out)
	}
	if got := strings.TrimSpace(string(out)); got != fakeBanner {
		t.Errorf("banner = %q, want %q", got, fakeBanner)
	}
}

// TestFakeInstallLayoutUnix checks the asdf layout of the fake installation: the
// Detect hook names it after its directory, 1.99.0-otp-26.
func TestFakeInstallLayoutUnix(t *testing.T) {
	fake := newFakeInstall(filepath.Join("/home", "user"), "26")

	wantRoot := filepath.Join("/home", "user", ".asdf", "installs", "elixir", "1.99.0-otp-26")
	if fake.root != wantRoot || fake.name != "1.99.0-otp-26" {
		t.Errorf("newFakeInstall() root %q name %q, want root %q name %q",
			fake.root, fake.name, wantRoot, "1.99.0-otp-26")
	}

	found := false
	for _, file := range fake.files {
		if file.path != "bin/elixir" {
			continue
		}
		found = true
		if file.mode != 0o755 {
			t.Errorf("bin/elixir mode %v, want 0755", file.mode)
		}
		if want := `echo "` + fakeBanner + `"`; !strings.Contains(file.content, want) {
			t.Errorf("bin/elixir does not print the banner: %q", file.content)
		}
	}
	if !found {
		t.Error("the fake installation has no bin/elixir")
	}
}

// TestShQuoteRoundTrip runs quoted words through a real shell and checks that
// the shell reads back each word unchanged.
func TestShQuoteRoundTrip(t *testing.T) {
	inputs := []string{"", "plain", "a b", "it's", `$HOME "x" *`, `back\slash`, "new\nline", "tab\tchar", "%s"}
	for _, in := range inputs {
		out, err := exec.Command("/bin/sh", "-c", "printf '%s' "+shQuote(in)).Output()
		if err != nil {
			t.Fatalf("sh with %q: %v", in, err)
		}
		if string(out) != in {
			t.Errorf("sh read %q back as %q", in, out)
		}
	}
}

// TestQuoteWordUnix checks the words of a logged command line on Unix.
func TestQuoteWordUnix(t *testing.T) {
	tests := []struct {
		in, want string
	}{
		{"elixir@1.16.2-otp-26", "elixir@1.16.2-otp-26"},
		{"", "''"},
		{"a b", "'a b'"},
		{"it's", `'it'\''s'`},
	}
	for _, tt := range tests {
		if got := quoteWord(tt.in); got != tt.want {
			t.Errorf("quoteWord(%q) = %s, want %s", tt.in, got, tt.want)
		}
	}
}

// TestEnvKeysAreCaseSensitiveUnix checks that HOME and home are different
// variables on Unix, so an override of one leaves the other alone.
func TestEnvKeysAreCaseSensitiveUnix(t *testing.T) {
	if envKeyFold("HOME") == envKeyFold("home") {
		t.Fatal("envKeyFold folds case on Unix")
	}
	got := vfoxEnv([]string{"home=/x"}, map[string]string{"HOME": "/y"})
	if want := []string{"home=/x", "HOME=/y"}; !slices.Equal(got, want) {
		t.Errorf("vfoxEnv() = %q, want %q", got, want)
	}
}

// TestIsolatedEnvUnix checks that the Unix isolation points HOME and the mise
// directory into the given user home.
func TestIsolatedEnvUnix(t *testing.T) {
	userHome := filepath.Join("/tmp", "user")
	env := isolatedEnv(userHome)
	if env["HOME"] != userHome {
		t.Errorf("HOME = %q, want %q", env["HOME"], userHome)
	}
	if want := filepath.Join(userHome, ".local", "share", "mise"); env["MISE_DATA_DIR"] != want {
		t.Errorf("MISE_DATA_DIR = %q, want %q", env["MISE_DATA_DIR"], want)
	}
}

// TestOfficialVersionUnix checks the version name of a source build on Unix.
func TestOfficialVersionUnix(t *testing.T) {
	if got := officialVersion("1.16.2", "26"); got != "1.16.2" {
		t.Errorf("officialVersion = %q, want 1.16.2", got)
	}
}

// TestHomeOnUnixHasNoSpace checks the constraint behind homeMayContainSpace: the
// default home of a Unix run has no space in its path.
func TestHomeOnUnixHasNoSpace(t *testing.T) {
	if homeMayContainSpace {
		t.Error("homeMayContainSpace is true on Unix")
	}
	if strings.Contains(homePattern, " ") {
		t.Errorf("homePattern %q has a space", homePattern)
	}
}
