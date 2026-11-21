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
	"bytes"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

// vfoxResult is the outcome of one vfox invocation.
type vfoxResult struct {
	command string // the command line as logged, for messages
	stdout  string
	stderr  string
	err     error // nil when vfox exited with status 0
}

// output returns stdout and stderr together. vfox prints its messages to
// either stream, so assertions on messages look at both.
func (r vfoxResult) output() string {
	return r.stdout + r.stderr
}

// runVfox runs the vfox binary once, in dir (the current directory when empty),
// with the isolated environment plus extra. It logs the command line and the
// output, and returns the result without failing the test.
func (s *suite) runVfox(t *testing.T, dir string, extra map[string]string, args ...string) vfoxResult {
	t.Helper()

	line := renderCommand(extra, append([]string{"vfox"}, args...))
	t.Logf("$ %s", line)

	cmd := exec.CommandContext(t.Context(), s.vfox, args...)
	cmd.Dir = dir
	cmd.Env = vfoxEnv(os.Environ(), s.environment(extra))
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()

	result := vfoxResult{command: line, stdout: stdout.String(), stderr: stderr.String(), err: err}
	if strings.TrimSpace(result.stdout) != "" {
		t.Logf("output:\n%s", strings.TrimRight(result.stdout, "\r\n"))
	}
	if strings.TrimSpace(result.stderr) != "" {
		t.Logf("stderr:\n%s", strings.TrimRight(result.stderr, "\r\n"))
	}
	if err != nil {
		t.Logf("vfox exited with an error: %v", err)
	}
	return result
}

// mustVfox runs vfox like runVfox and fails the test when it exits with an
// error. The failure message carries the output.
func (s *suite) mustVfox(t *testing.T, dir string, extra map[string]string, args ...string) vfoxResult {
	t.Helper()

	result := s.runVfox(t, dir, extra, args...)
	if result.err != nil {
		t.Fatalf("%s failed: %v\n--- output ---\n%s", result.command, result.err, result.output())
	}
	return result
}

// networkFailureMarkers are the messages of vfox, and of the HTTP client under
// it, for a download that broke off on the network: a connection that was closed
// or reset in the middle of a file, a timeout, or a host that did not answer. A
// failure without one of them, such as a build that fails, is not retried.
var networkFailureMarkers = []string{
	"failed to download",
	"unexpected EOF",
	"connection reset",
	"connection refused",
	"i/o timeout",
	"TLS handshake timeout",
	"no such host",
	"Failed to fetch",
}

// isNetworkFailure reports whether the output of a failed vfox command says that
// a download failed on the network.
func isNetworkFailure(output string) bool {
	for _, marker := range networkFailureMarkers {
		if strings.Contains(output, marker) {
			return true
		}
	}
	return false
}

// downloadVfox runs a vfox command that downloads something (add, install).
// When it fails on the network it is run again, up to networkAttempts attempts,
// retryDelay apart. Any other failure fails the test at once, with its output.
func (s *suite) downloadVfox(t *testing.T, extra map[string]string, args ...string) vfoxResult {
	t.Helper()

	var last vfoxResult
	for attempt := 1; ; attempt++ {
		last = s.runVfox(t, "", extra, args...)
		if last.err == nil {
			return last
		}
		if !isNetworkFailure(last.output()) {
			t.Fatalf("%s failed: %v\n--- output ---\n%s", last.command, last.err, last.output())
		}
		if attempt == networkAttempts {
			t.Fatalf("%s failed after %d attempts: %v\n--- output ---\n%s",
				last.command, networkAttempts, last.err, last.output())
		}
		t.Logf("attempt %d of %d failed on the network; retrying in %s", attempt, networkAttempts, retryDelay)
		select {
		case <-t.Context().Done():
			t.Fatalf("%s: %v", last.command, t.Context().Err())
		case <-time.After(retryDelay):
		}
	}
}
