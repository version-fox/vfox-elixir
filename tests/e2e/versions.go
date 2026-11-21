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

import "strings"

// windowsMarker separates the Elixir version from the OTP major in the names of
// the Windows versions, such as 1.16.2-elixir-otp-26.
const windowsMarker = "-elixir-otp-"

// splitWindowsVersion splits a Windows version name into the Elixir version and
// the OTP major. It cuts at the last "-elixir-otp-": an Elixir pre-release has a
// dash of its own (1.19.0-rc.2-elixir-otp-28), so cutting at the first dash
// would give the wrong Elixir version. ok is false unless the name has the form
// <elixir>-elixir-otp-<digits>, with an Elixir version that starts with a digit.
func splitWindowsVersion(name string) (elixir, otp string, ok bool) {
	i := strings.LastIndex(name, windowsMarker)
	if i < 0 {
		return "", "", false
	}
	elixir, otp = name[:i], name[i+len(windowsMarker):]
	if !startsWithDigit(elixir) || !isDigits(otp) {
		return "", "", false
	}
	return elixir, otp, true
}

// windowsInstallerURL returns the URL of the official installer that a Windows
// version name stands for. For 1.19.0-rc.2-elixir-otp-28 the release tag is
// v1.19.0-rc.2 and the asset is elixir-otp-28.exe. ok is false when the name is
// not a Windows version name.
func windowsInstallerURL(name string) (url string, ok bool) {
	elixir, otp, ok := splitWindowsVersion(name)
	if !ok {
		return "", false
	}
	return "https://github.com/elixir-lang/elixir/releases/download/v" + elixir +
		"/elixir-otp-" + otp + ".exe", true
}

// windowsVersionName returns the vfox version name of an official Windows
// installer, such as 1.16.2-elixir-otp-26.
func windowsVersionName(elixir, otp string) string {
	return elixir + windowsMarker + otp
}

// hexVersionName returns the vfox version name of a prebuilt build from
// builds.hex.pm, such as 1.16.2-otp-26.
func hexVersionName(elixir, otp string) string {
	return elixir + "-otp-" + otp
}

// otpMajor returns the major part of an Erlang/OTP version: 26 for 26.2.3.
func otpMajor(version string) string {
	major, _, _ := strings.Cut(version, ".")
	return major
}

// startsWithDigit reports whether s is non-empty and begins with an ASCII digit.
func startsWithDigit(s string) bool {
	return s != "" && s[0] >= '0' && s[0] <= '9'
}

// isDigits reports whether s is non-empty and holds only ASCII digits.
func isDigits(s string) bool {
	if s == "" {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}
