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
	"strings"
	"testing"
)

// erlProgram is the command that runs erl from an installed Erlang/OTP: the
// erl.exe in its bin directory. The extension is part of the name, see
// elixirProgram.
const erlProgram = "erl.exe"

// elixirProgram is the command that runs Elixir from an installed version: the
// bin\elixir.bat launcher. The extension is part of the name because vfox 1.1.0
// looks a command up in the PATH that EnvKeys sets by the name as typed, and it
// does not try the extensions of PATHEXT there. A bare "elixir" or "erl" is not
// found, and vfox exec then fails with "executable file not found in %PATH%".
const elixirProgram = "elixir.bat"

// homePattern is the name pattern of the VFOX_HOME that a Windows run creates
// when E2E_VFOX_HOME is unset. The path has no space, see homeMayContainSpace.
const homePattern = "vfox-home-"

// homeMayContainSpace is false on Windows too. The Erlang/OTP and Elixir steps
// run erl.exe and elixir.bat through vfox exec, and no step runs them from a
// path with a space. installSpacedHome checks the space case of the official
// installer on its own.
const homeMayContainSpace = false

// fakeWindowsElixir is bin\elixir.bat of a fake installation. Batch files need
// CRLF line endings, and the banner is printed for any arguments.
const fakeWindowsElixir = "@echo off\r\necho " + fakeBanner + "\r\n"

// officialVersion returns the vfox version name of an official Windows
// installer, such as 1.16.2-elixir-otp-26.
func officialVersion(elixir, otp string) string {
	return windowsVersionName(elixir, otp)
}

// isolatedEnv returns the variables that keep vfox and the Detect hook away from
// the real user's profile. The Detect hook reads %USERPROFILE%, %LOCALAPPDATA%
// and %ProgramFiles%; the last one is only read, never written.
func isolatedEnv(userHome string) map[string]string {
	return map[string]string{
		"USERPROFILE":  userHome,
		"HOME":         userHome,
		"LOCALAPPDATA": filepath.Join(userHome, "AppData", "Local"),
		"APPDATA":      filepath.Join(userHome, "AppData", "Roaming"),
	}
}

// envKeyFold normalizes a variable name for comparison. Windows names are
// case-insensitive.
func envKeyFold(key string) string {
	return strings.ToUpper(key)
}

// quoteWord quotes one word of a command line for the log, in the Windows
// command-line style: a word with a space, a tab or a double quote is wrapped in
// double quotes, and the double quotes inside it are escaped.
func quoteWord(word string) string {
	if word != "" && !strings.ContainsAny(word, " \t\"") {
		return word
	}
	return `"` + strings.ReplaceAll(word, `"`, `\"`) + `"`
}

// newFakeInstall describes a fake Elixir installation in the Scoop layout under
// userHome. The Detect hook names a Scoop installation after its VERSION file.
func newFakeInstall(userHome, otp string) fakeInstall {
	name := fakeElixirVersion
	return fakeInstall{
		root: filepath.Join(userHome, "scoop", "apps", "elixir", name),
		name: name,
		files: []fakeFile{
			fakeVersionFile(),
			{path: "bin/elixir.bat", content: fakeWindowsElixir, mode: 0o755},
		},
	}
}

// installOfficialElixir installs an official Elixir installer build, and checks
// that the install output names the installer that was downloaded. Then it runs
// hello.ex with it.
func (s *suite) installOfficialElixir(t *testing.T) {
	t.Helper()

	version := officialVersion(s.elixirVersion, s.otp)
	installer, ok := windowsInstallerURL(version)
	if !ok {
		t.Fatalf("%q is not a Windows version name", version)
	}
	spec := "elixir@" + version
	result := s.downloadVfox(t, nil, "install", "-y", spec)
	if !strings.Contains(result.output(), installer) {
		t.Fatalf("the install output does not name the installer %s\n--- output ---\n%s",
			installer, result.output())
	}
	s.runHello(t, spec)
}

// installHexMirror checks that hex.pm builds are refused on Windows: there are
// none, so the install must fail, and the message must say why.
func (s *suite) installHexMirror(t *testing.T) {
	t.Helper()

	spec := "elixir@" + hexVersionName(s.elixirVersion, s.otp)
	result := s.runVfox(t, "", map[string]string{"VFOX_ELIXIR_MIRROR": "hex"}, "install", "-y", spec)
	if result.err == nil {
		t.Fatalf("%s must fail on Windows, where hex.pm has no builds\n--- output ---\n%s",
			spec, result.output())
	}
	if !strings.Contains(result.output(), "Windows") {
		t.Fatalf("the failure should say that hex.pm builds are not available on Windows\n--- output ---\n%s",
			result.output())
	}
}

// checkHexSearch runs vfox search elixir hex, which must fail on Windows, where
// hex.pm has no builds, and say so.
func (s *suite) checkHexSearch(t *testing.T) {
	t.Helper()

	result := s.runVfox(t, "", nil, "search", "elixir", "hex")
	if result.err == nil {
		t.Fatalf("vfox search elixir hex must fail on Windows, where hex.pm has no builds\n--- output ---\n%s",
			result.output())
	}
	if !strings.Contains(result.output(), "not available on Windows") {
		t.Fatalf("the failure should say that the hex.pm builds are not available on Windows\n--- output ---\n%s",
			result.output())
	}
}

// installSpacedHome installs an official Elixir build into a vfox home whose path
// has a space, as the home of a Windows account with a space in its name would
// be, and checks the files that the installer writes. It needs no Erlang/OTP: the
// step checks the command line that the installer runs with, whose paths must be
// quoted for a space to survive.
func (s *suite) installSpacedHome(t *testing.T) {
	t.Helper()

	version := officialVersion(s.elixirVersion, s.otp)
	installer, ok := windowsInstallerURL(version)
	if !ok {
		t.Fatalf("%q is not a Windows version name", version)
	}
	home := tempDir(t, "vfox home-")
	if !strings.Contains(home, " ") {
		t.Fatalf("the temporary home %q has no space", home)
	}
	// The home reaches vfox through the environment of each command, so the
	// shared home of the suite is left alone.
	extra := map[string]string{"VFOX_HOME": home}
	s.downloadVfox(t, extra, "add", "--source", s.pluginZip, "elixir")
	result := s.downloadVfox(t, extra, "install", "-y", "elixir@"+version)
	if !strings.Contains(result.output(), installer) {
		t.Fatalf("the install output does not name the installer %s\n--- output ---\n%s",
			installer, result.output())
	}
	sdk := filepath.Join(home, "cache", "elixir", "v-"+version, "elixir-"+version)
	for _, file := range []string{"VERSION", filepath.Join("bin", "elixir.bat")} {
		if !pathExists(filepath.Join(sdk, file)) {
			t.Fatalf("the installer wrote no %s under %s\n--- output ---\n%s",
				file, sdk, result.output())
		}
	}
}
