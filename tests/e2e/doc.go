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

// Package e2e is the end-to-end suite of the Elixir plugin.
//
// TestE2E packs the plugin from this checkout, adds it to vfox, and installs
// real Erlang/OTP and Elixir versions through vfox. It checks that the
// installed tools run, and that the Detect hook finds an Elixir installation
// that is not managed by vfox. The steps run in order; each step's commands
// and output are logged.
//
// The other tests are unit tests of the helpers (plugin zip, shell quoting,
// version names, environment, fake installations). They need no vfox and run
// with:
//
//	go test -short ./...
//
// TestE2E needs vfox 1.1.0 or newer (for link --detect), network access to
// GitHub, and a source build of Erlang/OTP on Unix, so it takes a long time
// on a cold cache. The Linux run happens in the container described in
// linux/Dockerfile and docs/e2e.md:
//
//	go test -v -timeout 90m -run TestE2E ./...
//
// Environment variables:
//
//	VFOX_BIN            vfox binary under test (default: vfox on PATH)
//	E2E_VFOX_HOME       VFOX_HOME of the run. Unset: a new temporary directory,
//	                    removed at the end. Set: used as is and kept, so a
//	                    cache volume can hold the Erlang/OTP install.
//	E2E_ERLANG_VERSION  Erlang/OTP version (default 26.2.3)
//	E2E_ELIXIR_VERSION  Elixir version of the source and hex installs (default 1.16.2)
//	E2E_ERLANG_SOURCE   vfox-erlang source for vfox add (default: the main branch)
//
// The home and user-directory variables of every vfox process point into
// temporary directories created by the suite, never into the real user's
// home.
package e2e
