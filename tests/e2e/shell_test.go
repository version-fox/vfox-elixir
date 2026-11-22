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

import "testing"

// TestShQuote checks the quoting of single POSIX shell words. The round trip
// through a real shell is in platform_unix_test.go.
func TestShQuote(t *testing.T) {
	tests := []struct {
		in, want string
	}{
		{"", "''"},
		{"elixir", "'elixir'"},
		{"/tmp/vfox home-1", "'/tmp/vfox home-1'"},
		{"it's", `'it'\''s'`},
		{"'", `''\'''`},
		{`$HOME "x" *`, `'$HOME "x" *'`},
	}
	for _, tt := range tests {
		if got := shQuote(tt.in); got != tt.want {
			t.Errorf("shQuote(%q) = %s, want %s", tt.in, got, tt.want)
		}
	}
}

// TestRenderCommandSafeWords checks the log line for words that need no quoting
// on any platform.
func TestRenderCommandSafeWords(t *testing.T) {
	got := renderCommand(map[string]string{"VFOX_ELIXIR_MIRROR": "hex"},
		[]string{"install", "-y", "elixir@1.16.2-otp-26"})
	if want := "VFOX_ELIXIR_MIRROR=hex install -y elixir@1.16.2-otp-26"; got != want {
		t.Errorf("renderCommand() = %q, want %q", got, want)
	}
}

// TestRenderCommandOrdersAssignments checks that the environment assignments
// come first, sorted by name.
func TestRenderCommandOrdersAssignments(t *testing.T) {
	got := renderCommand(map[string]string{"B": "2", "A": "1"}, []string{"cmd"})
	if want := "A=1 B=2 cmd"; got != want {
		t.Errorf("renderCommand() = %q, want %q", got, want)
	}
}
