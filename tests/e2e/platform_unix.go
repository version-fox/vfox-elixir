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
	"path/filepath"
	"strings"
	"testing"
)

// erlProgram is the command that runs erl from an installed Erlang/OTP: the
// bin/erl script.
const erlProgram = "erl"

// elixirProgram is the command that runs Elixir from an installed version: the
// bin/elixir script.
const elixirProgram = "elixir"

// homePattern is the name pattern of the VFOX_HOME that a Unix run creates when
// E2E_VFOX_HOME is unset. The path has no space, because of homeMayContainSpace.
const homePattern = "vfox-home-"

// homeMayContainSpace is false on Unix. The Erlang/OTP source build, which every
// Unix run needs, runs OTP's erts/configure on the source tree, which lies under
// VFOX_HOME. That configure does not quote its paths: with a space in the path
// it fails with "cd: too many arguments" and then "cannot build emulator".
const homeMayContainSpace = false

// fakeUnixElixir is bin/elixir of a fake installation: a shell script that
// prints the banner whatever its arguments are.
const fakeUnixElixir = "#!/bin/sh\n# Fake Elixir installed by the vfox-elixir E2E suite.\necho \"" + fakeBanner + "\"\n"

// shellSafe holds the characters that need no quoting in a POSIX shell word.
const shellSafe = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@%+=:,./-_"

// officialVersion returns the vfox version name of the Elixir release built from
// source: the Elixir version itself, such as 1.16.2.
func officialVersion(elixir, otp string) string {
	return elixir
}

// isolatedEnv returns the variables that keep vfox and the Detect hook away from
// the real user's home. The Detect hook reads $HOME and $MISE_DATA_DIR.
func isolatedEnv(userHome string) map[string]string {
	return map[string]string{
		"HOME":          userHome,
		"MISE_DATA_DIR": filepath.Join(userHome, ".local", "share", "mise"),
	}
}

// envKeyFold normalizes a variable name for comparison. Unix names are
// case-sensitive.
func envKeyFold(key string) string {
	return key
}

// quoteWord quotes one word of a command line for the log, so that the line can
// be pasted into a POSIX shell.
func quoteWord(word string) string {
	if word != "" && strings.IndexFunc(word, func(r rune) bool {
		return !strings.ContainsRune(shellSafe, r)
	}) < 0 {
		return word
	}
	return shQuote(word)
}

// newFakeInstall describes a fake Elixir installation in the asdf layout under
// userHome. The Detect hook names an asdf installation after its directory.
func newFakeInstall(userHome, otp string) fakeInstall {
	name := fakeElixirVersion + "-otp-" + otp
	return fakeInstall{
		root: filepath.Join(userHome, ".asdf", "installs", "elixir", name),
		name: name,
		files: []fakeFile{
			fakeVersionFile(),
			{path: "bin/elixir", content: fakeUnixElixir, mode: 0o755},
		},
	}
}

// installOfficialElixir installs the Elixir release built from source, which
// needs erlc (found on PATH or in vfox's Erlang/OTP cache), and runs hello.ex
// with it.
func (s *suite) installOfficialElixir(t *testing.T) {
	t.Helper()

	spec := "elixir@" + officialVersion(s.elixirVersion, s.otp)
	s.downloadVfox(t, nil, "install", "-y", spec)
	s.runHello(t, spec)
}

// installHexMirror installs the prebuilt Elixir from builds.hex.pm, which needs
// no build, and runs hello.ex with it.
func (s *suite) installHexMirror(t *testing.T) {
	t.Helper()

	spec := "elixir@" + hexVersionName(s.elixirVersion, s.otp)
	s.downloadVfox(t, map[string]string{"VFOX_ELIXIR_MIRROR": "hex"}, "install", "-y", spec)
	s.runHello(t, spec)
}

// checkHexSearch runs vfox search elixir hex, which must list the hex.pm builds,
// each with its note.
func (s *suite) checkHexSearch(t *testing.T) {
	t.Helper()

	result := s.downloadVfox(t, nil, "search", "elixir", "hex")
	if !strings.Contains(result.output(), hexNote) {
		t.Fatalf("vfox search elixir hex must list the hex.pm builds\n--- output ---\n%s", result.output())
	}
}

// installSpacedHome is the Windows step that installs Elixir into a home with a
// space in its path. Unix has no official installer that runs into such a path,
// and its home may not contain a space at all, so the step is skipped here.
func (s *suite) installSpacedHome(t *testing.T) {
	t.Helper()

	t.Skip("the step with a space in the vfox home runs on Windows only")
}
