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

package e2e

import (
	"io/fs"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

// erlangProbe is the Erlang expression that prints the OTP release, which is the
// major version (26 for OTP 26.2.3).
const erlangProbe = `io:format("~s~n",[erlang:system_info(otp_release)]), halt().`

// TestE2E installs real Erlang/OTP and Elixir versions through vfox, with the
// plugin packed from this checkout, and checks that they run. The steps run in
// order. Adding the plugins and installing Erlang/OTP are required by the rest,
// so a failure there ends the test; the other steps run regardless. The steps
// that differ between Unix and Windows are in platform_unix.go and
// platform_windows.go.
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("TestE2E installs Erlang/OTP and Elixir; it is skipped in -short mode")
	}
	s := newSuite(t)

	t.Run("vfox version", s.printVersion)
	if !t.Run("add plugins", s.addPlugins) {
		t.Fatal("the plugins are needed by every later step")
	}
	// Needs no Erlang/OTP, so it runs before the Erlang/OTP steps.
	t.Run("installer in a spaced home", s.installSpacedHome)
	if !t.Run("erlang", s.installErlang) {
		t.Fatal("Erlang/OTP is needed by the Elixir steps")
	}
	t.Run("elixir", s.installOfficialElixir)
	t.Run("hex mirror", s.installHexMirror)
	t.Run("detect", s.detectFakeInstall)
}

// printVersion logs the version of vfox under test. It asserts nothing: the
// Detect step fails on a vfox that is too old for it.
func (s *suite) printVersion(t *testing.T) {
	t.Helper()

	result := s.mustVfox(t, "", nil, "--version")
	t.Logf("vfox under test: %s", lastLine(result.output()))
}

// addPlugins adds the Elixir plugin packed from this checkout, and the
// Erlang/OTP plugin.
func (s *suite) addPlugins(t *testing.T) {
	t.Helper()

	// Elixir is always added afresh. A home kept from an earlier run may hold
	// its plugin and the versions installed with it, and vfox add refuses to
	// replace a plugin, so vfox remove clears both first. Erlang/OTP is kept:
	// its install is the slow part of a cold run.
	if pathExists(s.pluginPath("elixir")) || pathExists(s.sdkRoot("elixir")) {
		if removed := s.runVfox(t, "", nil, "remove", "-y", "elixir"); removed.err != nil {
			t.Logf("vfox remove elixir failed; the add below reports what is left: %v", removed.err)
		}
	}
	s.mustVfox(t, "", nil, "add", "--source", s.pluginZip, "elixir")

	if pathExists(s.pluginPath("erlang")) {
		t.Log("the Erlang/OTP plugin is already in VFOX_HOME, so vfox add is skipped")
		return
	}
	s.downloadVfox(t, nil, "add", "--source", s.erlangSource, "erlang")
}

// installErlang makes sure that Erlang/OTP is installed and that erl reports the
// expected OTP release. An install that is already in VFOX_HOME, such as one
// kept in a cache volume, is not installed again; it is probed, and reinstalled
// only when the probe fails.
func (s *suite) installErlang(t *testing.T) {
	t.Helper()

	spec := "erlang@" + s.erlangVersion
	if pathExists(s.sdkDir("erlang", s.erlangVersion)) {
		if s.erlangReports(s.probeErlang(t)) {
			t.Logf("%s is already installed in VFOX_HOME; vfox install is skipped", spec)
			return
		}
		t.Logf("%s is in VFOX_HOME, but erl does not report OTP %s; reinstalling it", spec, s.otp)
		s.downloadVfox(t, nil, "install", "-y", "--reinstall", spec)
	} else {
		s.downloadVfox(t, nil, "install", "-y", spec)
	}

	probe := s.probeErlang(t)
	if !s.erlangReports(probe) {
		// Where the installer put erl, for the failure message: vfox exec looks
		// only where EnvKeys says.
		where := strings.Join(findNamed(s.sdkRoot("erlang"), "erl", "erl.exe"), "\n")
		t.Fatalf("erl does not report OTP %s after installing %s\n--- erl under the cache ---\n%s\n--- output ---\n%s",
			s.otp, spec, where, probe.output())
	}
}

// probeErlang runs erl under the installed Erlang/OTP and returns the result.
func (s *suite) probeErlang(t *testing.T) vfoxResult {
	t.Helper()

	return s.runVfox(t, "", nil, "exec", "erlang@"+s.erlangVersion, "--",
		"erl", "-noshell", "-eval", erlangProbe)
}

// erlangReports reports whether a probe succeeded and printed the expected OTP
// major version as its last line.
func (s *suite) erlangReports(probe vfoxResult) bool {
	return probe.err == nil && lastLine(probe.stdout) == s.otp
}

// runHello runs assets/hello.ex with elixirSpec (such as elixir@1.16.2) under
// the installed Erlang/OTP, and checks the output. The file is copied into a
// fresh directory, so the run does not depend on the repository's layout.
func (s *suite) runHello(t *testing.T, elixirSpec string) {
	t.Helper()

	dir := s.newWorkDir(t)
	if err := copyFile(filepath.Join(s.repoRoot, "assets", "hello.ex"), filepath.Join(dir, "hello.ex")); err != nil {
		t.Fatalf("copy hello.ex: %v", err)
	}
	result := s.mustVfox(t, dir, nil, "exec", "erlang@"+s.erlangVersion, elixirSpec,
		"--", elixirProgram, "hello.ex")
	if !strings.Contains(result.output(), helloOutput) {
		t.Fatalf("elixir hello.ex did not print %q\n--- output ---\n%s", helloOutput, result.output())
	}
}

// detectFakeInstall puts an Elixir installation that vfox does not manage in the
// user home, then checks that link --detect lists it and that the linked
// version runs.
func (s *suite) detectFakeInstall(t *testing.T) {
	t.Helper()

	fake := newFakeInstall(s.userHome, s.otp)
	if err := writeFakeInstall(fake); err != nil {
		t.Fatalf("create the fake installation at %s: %v", fake.root, err)
	}
	t.Logf("fake installation %s at %s", fake.name, fake.root)

	found := s.mustVfox(t, "", nil, "link", "--detect", "-y", "elixir")
	out := found.output()
	if !strings.Contains(out, "Found:") || !strings.Contains(out, "elixir@"+fake.name) || !containsPath(out, fake.root) {
		t.Fatalf("link --detect did not list elixir@%s at %s\n--- output ---\n%s", fake.name, fake.root, out)
	}

	run := s.mustVfox(t, "", nil, "exec", "elixir@"+fake.name, "--", elixirProgram, "--version")
	if !strings.Contains(run.output(), fakeBanner) {
		t.Fatalf("elixir --version through the linked version did not print %q\n--- output ---\n%s",
			fakeBanner, run.output())
	}
}

// containsPath reports whether output mentions path, written with either kind
// of separator.
func containsPath(output, path string) bool {
	return strings.Contains(output, path) || strings.Contains(output, filepath.ToSlash(path))
}

// findNamed lists the files under root whose names are among names, so that a
// failure can say where an installer put a program. It lists one line saying
// none when there is none.
func findNamed(root string, names ...string) []string {
	var found []string
	_ = filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err == nil && !entry.IsDir() && slices.Contains(names, entry.Name()) {
			found = append(found, path)
		}
		return nil
	})
	if len(found) == 0 {
		return []string{"(none under " + root + ")"}
	}
	return found
}
