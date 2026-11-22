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

// TestIsNetworkFailure checks that only a download that broke off on the network
// is retried: a build or a missing version fails at once.
func TestIsNetworkFailure(t *testing.T) {
	network := []string{
		"failed to download elixir@1.16.2 file, err:unexpected EOF",
		"Failed to fetch the Elixir versions from https://fastly.jsdelivr.net/gh/version-fox/vfox-elixir@main/assets/versions.txt: read tcp: connection reset by peer",
	}
	for _, output := range network {
		if !isNetworkFailure(output) {
			t.Errorf("isNetworkFailure(%q) = false, want true", output)
		}
	}

	other := []string{
		"plugin [PostInstall] method error: post_install.lua:43: Elixir build failed: make stopped with an error. Check the output above for the cause; see https://github.com/version-fox/vfox-elixir/blob/main/docs/troubleshooting.md",
		"Elixir 1.99.0 was not found. Please confirm that the version exists",
		"Install elixir@1.16.2-otp-26 success!",
		"",
	}
	for _, output := range other {
		if isNetworkFailure(output) {
			t.Errorf("isNetworkFailure(%q) = true, want false", output)
		}
	}
}
