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

// shQuote returns s as one POSIX shell word, in single quotes. Each single
// quote in s becomes '\” (close the quote, write an escaped quote, reopen it),
// so the word is the same to sh, bash and zsh whatever s contains.
func shQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

// renderCommand joins the environment assignments and the arguments into one
// command line for the log. Each word is quoted for the platform's shell
// (quoteWord), so that a logged line can be pasted and run. The assignments
// come first, sorted by name.
func renderCommand(env map[string]string, args []string) string {
	words := make([]string, 0, len(env)+len(args))
	for _, name := range slices.Sorted(maps.Keys(env)) {
		words = append(words, name+"="+quoteWord(env[name]))
	}
	for _, arg := range args {
		words = append(words, quoteWord(arg))
	}
	return strings.Join(words, " ")
}
