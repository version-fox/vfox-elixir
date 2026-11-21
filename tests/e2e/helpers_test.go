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
	"os"
	"path/filepath"
	"testing"
)

// writeTestFile writes content to the file rel under root, creating the
// directories on the way.
func writeTestFile(t *testing.T, root, rel, content string) {
	t.Helper()

	path := filepath.Join(root, filepath.FromSlash(rel))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

// TestLastLine checks that lastLine returns the last non-empty line, trimmed.
func TestLastLine(t *testing.T) {
	tests := []struct {
		output, want string
	}{
		{"26\n", "26"},
		{"warning\n26\n", "26"},
		{"  26  \r\n", "26"},
		{"26\n\n\n", "26"},
		{"", ""},
	}
	for _, tt := range tests {
		if got := lastLine(tt.output); got != tt.want {
			t.Errorf("lastLine(%q) = %q, want %q", tt.output, got, tt.want)
		}
	}
}

// TestContainsPath checks that containsPath finds a path in the output.
func TestContainsPath(t *testing.T) {
	output := "Found:\n  elixir@1.99.0-otp-26  /tmp/elixir e2e/root  (installed by asdf)\n"
	if !containsPath(output, "/tmp/elixir e2e/root") {
		t.Error("containsPath did not find a path that the output names")
	}
	if containsPath(output, "/tmp/elixir e2e/other") {
		t.Error("containsPath found a path that the output does not name")
	}
}
