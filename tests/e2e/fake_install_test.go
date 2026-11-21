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

// TestWriteFakeInstall checks that the files of a fake installation are written
// under its root, including in a path with a space.
func TestWriteFakeInstall(t *testing.T) {
	root := filepath.Join(t.TempDir(), "with space", "root")
	install := fakeInstall{
		root: root,
		name: "1.99.0",
		files: []fakeFile{
			fakeVersionFile(),
			{path: "bin/tool", content: "#!/bin/sh\n", mode: 0o755},
		},
	}
	if err := writeFakeInstall(install); err != nil {
		t.Fatalf("writeFakeInstall: %v", err)
	}

	for _, file := range install.files {
		data, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(file.path)))
		if err != nil {
			t.Fatalf("read %s: %v", file.path, err)
		}
		if string(data) != file.content {
			t.Errorf("%s = %q, want %q", file.path, data, file.content)
		}
	}
}

// TestFakeVersionFile checks the VERSION file that the Detect hook reads.
func TestFakeVersionFile(t *testing.T) {
	file := fakeVersionFile()
	if file.path != "VERSION" || file.content != "1.99.0\n" {
		t.Errorf("fakeVersionFile() = %q with %q, want VERSION with %q", file.path, file.content, "1.99.0\n")
	}
}
