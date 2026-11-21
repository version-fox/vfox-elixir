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

// TestSplitWindowsVersion checks the split at the last "-elixir-otp-". The
// release candidate case is the one that a split at the first dash gets wrong.
func TestSplitWindowsVersion(t *testing.T) {
	tests := []struct {
		name, elixir, otp string
		ok                bool
	}{
		{"1.16.2-elixir-otp-26", "1.16.2", "26", true},
		{"1.19.5-elixir-otp-28", "1.19.5", "28", true},
		{"1.19.0-rc.2-elixir-otp-28", "1.19.0-rc.2", "28", true},
		{"1.16.2-otp-26", "", "", false},
		{"1.16.2", "", "", false},
		{"-elixir-otp-26", "", "", false},
		{"1.16.2-elixir-otp-", "", "", false},
		{"1.16.2-elixir-otp-26-rc1", "", "", false},
		{"v1.16.2-elixir-otp-26", "", "", false},
	}
	for _, tt := range tests {
		elixir, otp, ok := splitWindowsVersion(tt.name)
		if elixir != tt.elixir || otp != tt.otp || ok != tt.ok {
			t.Errorf("splitWindowsVersion(%q) = (%q, %q, %v), want (%q, %q, %v)",
				tt.name, elixir, otp, ok, tt.elixir, tt.otp, tt.ok)
		}
	}
}

// TestWindowsInstallerURL checks the installer URL of a Windows version name.
// A pre-release is a tag of its own: v1.19.0-rc.2 with the asset elixir-otp-28.exe.
func TestWindowsInstallerURL(t *testing.T) {
	tests := []struct {
		name, want string
	}{
		{
			"1.16.2-elixir-otp-26",
			"https://github.com/elixir-lang/elixir/releases/download/v1.16.2/elixir-otp-26.exe",
		},
		{
			"1.19.0-rc.2-elixir-otp-28",
			"https://github.com/elixir-lang/elixir/releases/download/v1.19.0-rc.2/elixir-otp-28.exe",
		},
	}
	for _, tt := range tests {
		got, ok := windowsInstallerURL(tt.name)
		if !ok || got != tt.want {
			t.Errorf("windowsInstallerURL(%q) = (%q, %v), want (%q, true)", tt.name, got, ok, tt.want)
		}
	}
	if got, ok := windowsInstallerURL("1.16.2-otp-26"); ok {
		t.Errorf("windowsInstallerURL of a hex name = %q, want no URL", got)
	}
}

// TestVersionNames checks how the suite names the versions it installs.
func TestVersionNames(t *testing.T) {
	if got := windowsVersionName("1.19.0-rc.2", "28"); got != "1.19.0-rc.2-elixir-otp-28" {
		t.Errorf("windowsVersionName = %q", got)
	}
	if got := hexVersionName("1.16.2", "26"); got != "1.16.2-otp-26" {
		t.Errorf("hexVersionName = %q", got)
	}
	if got := otpMajor("26.2.3"); got != "26" {
		t.Errorf("otpMajor(26.2.3) = %q, want 26", got)
	}
	if got := otpMajor("27"); got != "27" {
		t.Errorf("otpMajor(27) = %q, want 27", got)
	}
}
