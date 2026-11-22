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
	"slices"
	"testing"
)

// TestVfoxEnv checks that vfoxEnv drops the vfox variables of the caller,
// replaces overridden variables instead of duplicating them, and removes a
// variable whose override is empty.
func TestVfoxEnv(t *testing.T) {
	base := []string{
		"PATH=/usr/bin",
		"HOME=/home/user",
		"VFOX_HOME=/real/home",
		"VFOX_ELIXIR_MIRROR=hex",
		"__VFOX_SHELL=bash",
		"LANG=C.UTF-8",
	}
	overrides := map[string]string{
		"HOME":               "/tmp/home",
		"VFOX_HOME":          "/tmp/vfox home",
		"VFOX_ELIXIR_MIRROR": "",
	}
	want := []string{"PATH=/usr/bin", "LANG=C.UTF-8", "HOME=/tmp/home", "VFOX_HOME=/tmp/vfox home"}

	if got := vfoxEnv(base, overrides); !slices.Equal(got, want) {
		t.Errorf("vfoxEnv() =\n%q\nwant\n%q", got, want)
	}
}

// TestVfoxEnvReplacesOverriddenVariable checks that an override replaces the
// variable it names, rather than being added next to it.
func TestVfoxEnvReplacesOverriddenVariable(t *testing.T) {
	got := vfoxEnv([]string{"HOME=/a", "PATH=/bin"}, map[string]string{"HOME": "/b"})
	want := []string{"PATH=/bin", "HOME=/b"}
	if !slices.Equal(got, want) {
		t.Errorf("vfoxEnv() = %q, want %q", got, want)
	}
}

// TestVfoxEnvSortsOverrides checks that the overrides come out in a fixed order,
// so that the environment does not change from one run to the next.
func TestVfoxEnvSortsOverrides(t *testing.T) {
	got := vfoxEnv(nil, map[string]string{"VFOX_HOME": "/v", "HOME": "/h", "MISE_DATA_DIR": "/m"})
	want := []string{"HOME=/h", "MISE_DATA_DIR=/m", "VFOX_HOME=/v"}
	if !slices.Equal(got, want) {
		t.Errorf("vfoxEnv() = %q, want %q", got, want)
	}
}

// TestIsVfoxVariable checks which names are vfox's own variables.
func TestIsVfoxVariable(t *testing.T) {
	tests := []struct {
		key  string
		want bool
	}{
		{"VFOX_HOME", true},
		{"vfox_home", true},
		{"__VFOX_SHELL", true},
		{"VFOXHOME", false},
		{"PATH", false},
		{"", false},
	}
	for _, tt := range tests {
		if got := isVfoxVariable(tt.key); got != tt.want {
			t.Errorf("isVfoxVariable(%q) = %v, want %v", tt.key, got, tt.want)
		}
	}
}
