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

//go:build windows

package e2e

import (
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

// TestFakeWindowsElixirScript checks the batch file of the fake installation.
// cmd needs CRLF line endings, so no bare LF may appear in it.
func TestFakeWindowsElixirScript(t *testing.T) {
	if !strings.HasPrefix(fakeWindowsElixir, "@echo off\r\n") {
		t.Errorf("fakeWindowsElixir does not start with @echo off: %q", fakeWindowsElixir)
	}
	if !strings.Contains(fakeWindowsElixir, fakeBanner) {
		t.Errorf("fakeWindowsElixir does not print the banner: %q", fakeWindowsElixir)
	}
	if strings.Count(fakeWindowsElixir, "\n") != strings.Count(fakeWindowsElixir, "\r\n") {
		t.Errorf("fakeWindowsElixir has a bare LF: %q", fakeWindowsElixir)
	}
}

// TestFakeInstallLayoutWindows checks the Scoop layout of the fake installation:
// the Detect hook names it after its VERSION file, 1.99.0.
func TestFakeInstallLayoutWindows(t *testing.T) {
	userHome := `C:\Users\user`
	fake := newFakeInstall(userHome, "26")

	wantRoot := filepath.Join(userHome, "scoop", "apps", "elixir", "1.99.0")
	if fake.root != wantRoot || fake.name != "1.99.0" {
		t.Errorf("newFakeInstall() root %q name %q, want root %q name %q",
			fake.root, fake.name, wantRoot, "1.99.0")
	}
	found := false
	for _, file := range fake.files {
		if file.path == "bin/elixir.bat" {
			found = true
		}
	}
	if !found {
		t.Error("the fake installation has no bin/elixir.bat")
	}
}

// TestOfficialVersionWindows checks the version name of an installer build, for
// a release candidate as well.
func TestOfficialVersionWindows(t *testing.T) {
	version := officialVersion("1.19.0-rc.2", "28")
	if version != "1.19.0-rc.2-elixir-otp-28" {
		t.Errorf("officialVersion = %q", version)
	}
	if _, ok := windowsInstallerURL(version); !ok {
		t.Errorf("windowsInstallerURL(%q) has no URL", version)
	}
}

// TestEnvKeysFoldWindows checks that variable names are case-insensitive on
// Windows, so that an override of Home replaces Home.
func TestEnvKeysFoldWindows(t *testing.T) {
	if envKeyFold("Path") != envKeyFold("PATH") {
		t.Fatal("envKeyFold does not fold case on Windows")
	}
	got := vfoxEnv([]string{"Home=/x", "PATH=/bin"}, map[string]string{"HOME": "/y"})
	if want := []string{"PATH=/bin", "HOME=/y"}; !slices.Equal(got, want) {
		t.Errorf("vfoxEnv() = %q, want %q", got, want)
	}
}

// TestQuoteWordWindows checks the words of a logged command line on Windows.
func TestQuoteWordWindows(t *testing.T) {
	tests := []struct {
		in, want string
	}{
		{"elixir@1.16.2-elixir-otp-26", "elixir@1.16.2-elixir-otp-26"},
		{"", `""`},
		{`C:\Program Files\x`, `"C:\Program Files\x"`},
		{`say "hi"`, `"say \"hi\""`},
	}
	for _, tt := range tests {
		if got := quoteWord(tt.in); got != tt.want {
			t.Errorf("quoteWord(%q) = %s, want %s", tt.in, got, tt.want)
		}
	}
}

// TestIsolatedEnvWindows checks that the Windows isolation points the profile
// and the local application data into the given user home.
func TestIsolatedEnvWindows(t *testing.T) {
	userHome := `C:\Users\user`
	env := isolatedEnv(userHome)
	if env["USERPROFILE"] != userHome {
		t.Errorf("USERPROFILE = %q, want %q", env["USERPROFILE"], userHome)
	}
	if want := filepath.Join(userHome, "AppData", "Local"); env["LOCALAPPDATA"] != want {
		t.Errorf("LOCALAPPDATA = %q, want %q", env["LOCALAPPDATA"], want)
	}
}

// TestHomeOnWindowsHasSpace checks that the default Windows home has a space in
// its path, which covers the quoting of the installer path (fix 1).
func TestHomeOnWindowsHasSpace(t *testing.T) {
	if !homeMayContainSpace {
		t.Error("homeMayContainSpace is false on Windows")
	}
	if !strings.Contains(homePattern, " ") {
		t.Errorf("homePattern %q has no space", homePattern)
	}
}
