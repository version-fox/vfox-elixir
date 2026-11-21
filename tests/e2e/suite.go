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
	"maps"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

const (
	defaultErlangVersion = "26.2.3"
	defaultElixirVersion = "1.16.2"
	defaultErlangSource  = "https://github.com/version-fox/vfox-erlang/archive/refs/heads/main.zip"

	// networkAttempts and retryDelay bound the retries of the vfox commands
	// that download something (add and install) when they fail on the network;
	// see isNetworkFailure. Other failures are not retried.
	networkAttempts = 5
	retryDelay      = 10 * time.Second
)

// helloOutput is the line that assets/hello.ex prints.
const helloOutput = "Hello world from Elixir"

// suite is the state that the steps of TestE2E share.
type suite struct {
	repoRoot      string // root of the plugin checkout, the parent of tests/
	vfox          string // the vfox binary under test
	home          string // VFOX_HOME of every vfox process
	userHome      string // HOME (and USERPROFILE on Windows) of every vfox process
	work          string // scratch directory for the steps
	pluginZip     string // the Elixir plugin, packed from repoRoot
	erlangSource  string // source given to vfox add for the Erlang/OTP plugin
	erlangVersion string // Erlang/OTP version, such as 26.2.3
	elixirVersion string // Elixir version of the source and hex installs, such as 1.16.2
	otp           string // major part of erlangVersion, such as 26
}

// newSuite reads the configuration from the environment, creates the
// directories and packs the plugin. Temporary directories are removed when the
// test ends. A home given through E2E_VFOX_HOME is kept, because it may be a
// cache volume.
func newSuite(t *testing.T) *suite {
	t.Helper()

	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve the repository root: %v", err)
	}
	if !pathExists(filepath.Join(repoRoot, "metadata.lua")) {
		t.Fatalf("%s has no metadata.lua: run the suite from tests/e2e", repoRoot)
	}

	vfoxName := envOr("VFOX_BIN", "vfox")
	vfox, err := exec.LookPath(vfoxName)
	if err != nil {
		t.Fatalf("vfox binary %q not found; install vfox 1.1.0 or set VFOX_BIN: %v", vfoxName, err)
	}

	home := os.Getenv("E2E_VFOX_HOME")
	if home == "" {
		home = tempDir(t, homePattern)
	} else if home, err = filepath.Abs(home); err != nil {
		t.Fatalf("resolve E2E_VFOX_HOME: %v", err)
	}
	if !homeMayContainSpace && strings.Contains(home, " ") {
		// Checked here, not at the Erlang/OTP build: the build takes a long
		// time and then fails inside OTP's configure.
		t.Fatalf("E2E_VFOX_HOME %q has a space in its path; on this platform the Erlang/OTP source build cannot use such a path, so use one without spaces", home)
	}
	// vfox 1.1.0 creates plugin/ and cache/ inside VFOX_HOME with os.Mkdir, so
	// the home itself must exist before the first vfox command. Without it,
	// vfox add fails with "rename ... no such file or directory". The other
	// directories (plugin/, cache/, sdks/ and the user's ~/.vfox/tmp) are
	// created by vfox on demand, verified against vfox 1.1.0.
	if err := os.MkdirAll(home, 0o755); err != nil {
		t.Fatalf("create E2E_VFOX_HOME: %v", err)
	}

	s := &suite{
		repoRoot:      repoRoot,
		vfox:          vfox,
		home:          home,
		userHome:      tempDir(t, "elixir-e2e-home-"),
		work:          tempDir(t, "elixir-e2e-work-"),
		erlangSource:  envOr("E2E_ERLANG_SOURCE", defaultErlangSource),
		erlangVersion: envOr("E2E_ERLANG_VERSION", defaultErlangVersion),
		elixirVersion: envOr("E2E_ELIXIR_VERSION", defaultElixirVersion),
	}
	s.otp = otpMajor(s.erlangVersion)
	s.pluginZip = filepath.Join(s.work, "elixir.zip")
	if err := buildPluginZip(repoRoot, s.pluginZip); err != nil {
		t.Fatalf("pack the plugin: %v", err)
	}

	t.Logf("vfox binary: %s", vfox)
	t.Logf("VFOX_HOME: %s", home)
	t.Logf("isolated user home: %s", s.userHome)
	t.Logf("Erlang/OTP %s (OTP %s), Elixir %s, Erlang/OTP plugin source: %s",
		s.erlangVersion, s.otp, s.elixirVersion, s.erlangSource)
	t.Logf("plugin zip: %s", s.pluginZip)
	return s
}

// environment returns the variables of one vfox process: the isolated home
// first (VFOX_HOME and the user home, so that nothing under the real user's
// home is read or written), then extra. An empty value in extra removes the
// variable.
func (s *suite) environment(extra map[string]string) map[string]string {
	env := isolatedEnv(s.userHome)
	env["VFOX_HOME"] = s.home
	maps.Copy(env, extra)
	return env
}

// pluginPath is where vfox keeps a plugin: <VFOX_HOME>/plugin/<name>.
func (s *suite) pluginPath(name string) string {
	return filepath.Join(s.home, "plugin", name)
}

// sdkRoot is where vfox keeps the installed versions of an SDK:
// <VFOX_HOME>/cache/<name>. Removing a plugin with vfox remove also removes
// this directory.
func (s *suite) sdkRoot(name string) string {
	return filepath.Join(s.home, "cache", name)
}

// sdkDir is the directory of one installed version:
// <VFOX_HOME>/cache/<name>/v-<version>.
func (s *suite) sdkDir(name, version string) string {
	return filepath.Join(s.sdkRoot(name), "v-"+version)
}

// newWorkDir creates an empty scratch directory for one step.
func (s *suite) newWorkDir(t *testing.T) string {
	t.Helper()
	dir, err := os.MkdirTemp(s.work, "step-")
	if err != nil {
		t.Fatalf("create a work directory: %v", err)
	}
	return dir
}

// tempDir creates a temporary directory that is removed when the test ends.
// Removal errors are ignored: on Windows a process may still hold a file open
// for a moment after it exits.
func tempDir(t *testing.T, pattern string) string {
	t.Helper()
	dir, err := os.MkdirTemp("", pattern)
	if err != nil {
		t.Fatalf("create a temporary directory: %v", err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(dir) })
	return dir
}

// envOr returns the value of the environment variable name, or fallback when
// it is unset or empty.
func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

// pathExists reports whether path can be stat'ed.
func pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// lastLine returns the last non-empty line of output, trimmed.
func lastLine(output string) string {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	return strings.TrimSpace(lines[len(lines)-1])
}

// copyFile copies the file src to dst, which is created with mode 0644.
func copyFile(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, data, 0o644)
}
