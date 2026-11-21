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
)

const (
	// fakeElixirVersion is the version that the fake installation reports.
	fakeElixirVersion = "1.99.0"
	// fakeBanner is what the fake elixir program prints for --version.
	fakeBanner = "Elixir 1.99.0 (fake)"
)

// fakeFile is one file of a fake installation.
type fakeFile struct {
	path    string // slash-separated, relative to the installation root
	content string
	mode    os.FileMode
}

// fakeInstall is an Elixir installation that vfox does not manage. The Detect
// hook should find it and link it.
type fakeInstall struct {
	root  string     // installation root
	name  string     // the version name that the Detect hook gives it
	files []fakeFile // files under root
}

// fakeVersionFile is the VERSION file of a fake installation. The Detect hook
// reads it for the version name on Windows.
func fakeVersionFile() fakeFile {
	return fakeFile{path: "VERSION", content: fakeElixirVersion + "\n", mode: 0o644}
}

// writeFakeInstall creates the files of install under its root.
func writeFakeInstall(install fakeInstall) error {
	for _, file := range install.files {
		path := filepath.Join(install.root, filepath.FromSlash(file.path))
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(path, []byte(file.content), file.mode); err != nil {
			return err
		}
		// WriteFile applies the mode only when it creates the file, and the
		// umask may have cleared some of its bits, so set it again.
		if err := os.Chmod(path, file.mode); err != nil {
			return err
		}
	}
	return nil
}
