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
	"slices"
	"strings"
)

// vfoxEnv returns the environment of one vfox process. It starts from base,
// without the VFOX_* and __VFOX_* variables: a shell where vfox is activated
// would otherwise leak its state into the run, and a stray VFOX_ELIXIR_MIRROR
// would change what the plugin installs. Then the overrides are added, sorted by
// name. An override with an empty value removes the variable.
func vfoxEnv(base []string, overrides map[string]string) []string {
	overridden := make(map[string]bool, len(overrides))
	for name := range overrides {
		overridden[envKeyFold(name)] = true
	}

	env := make([]string, 0, len(base)+len(overrides))
	for _, entry := range base {
		key, _, _ := strings.Cut(entry, "=")
		if isVfoxVariable(key) || overridden[envKeyFold(key)] {
			continue
		}
		env = append(env, entry)
	}
	for _, name := range slices.Sorted(maps.Keys(overrides)) {
		if value := overrides[name]; value != "" {
			env = append(env, name+"="+value)
		}
	}
	return env
}

// isVfoxVariable reports whether key names a variable of vfox itself (VFOX_* or
// __VFOX_*). The match ignores case, which is what Windows does and is harmless
// elsewhere.
func isVfoxVariable(key string) bool {
	upper := strings.ToUpper(key)
	return strings.HasPrefix(upper, "VFOX_") || strings.HasPrefix(upper, "__VFOX_")
}
