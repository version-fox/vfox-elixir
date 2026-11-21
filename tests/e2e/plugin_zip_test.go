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
	"archive/zip"
	"io"
	"path/filepath"
	"slices"
	"testing"
)

// TestBuildPluginZipPacksOnlyThePlugin checks which files go into the zip, and
// that their contents are the files' own.
func TestBuildPluginZipPacksOnlyThePlugin(t *testing.T) {
	repo := t.TempDir()
	files := map[string]string{
		"metadata.lua":           "PLUGIN = {}\n",
		"hooks/available.lua":    "function PLUGIN:Available(ctx) return {} end\n",
		"hooks/pre_install.lua":  "function PLUGIN:PreInstall(ctx) return {} end\n",
		"hooks/README.md":        "not a hook\n",
		"hooks/nested/extra.lua": "hooks are read one level deep, so this is not packed\n",
		"lib/elixir_utils.lua":   "return {}\n",
		"Injection.lua":          "-- not part of the plugin\n",
		"tests/pre_use_test.lua": "-- not part of the plugin\n",
		"assets/hello.ex":        "IO.puts(\"Hello world from Elixir\")\n",
	}
	for name, content := range files {
		writeTestFile(t, repo, name, content)
	}

	zipPath := filepath.Join(t.TempDir(), "elixir.zip")
	if err := buildPluginZip(repo, zipPath); err != nil {
		t.Fatalf("buildPluginZip: %v", err)
	}

	reader, err := zip.OpenReader(zipPath)
	if err != nil {
		t.Fatalf("open the zip: %v", err)
	}
	defer func() { _ = reader.Close() }()

	var names []string
	for _, file := range reader.File {
		names = append(names, file.Name)
	}
	want := []string{"hooks/available.lua", "hooks/pre_install.lua", "lib/elixir_utils.lua", "metadata.lua"}
	if !slices.Equal(names, want) {
		t.Fatalf("zip entries = %q, want %q", names, want)
	}

	for _, file := range reader.File {
		rc, err := file.Open()
		if err != nil {
			t.Fatalf("open entry %s: %v", file.Name, err)
		}
		data, err := io.ReadAll(rc)
		_ = rc.Close()
		if err != nil {
			t.Fatalf("read entry %s: %v", file.Name, err)
		}
		if string(data) != files[file.Name] {
			t.Errorf("entry %s = %q, want %q", file.Name, data, files[file.Name])
		}
	}
}

// TestBuildPluginZipNeedsAPlugin checks that a checkout without the plugin's
// parts is an error, not an empty or partial zip.
func TestBuildPluginZipNeedsAPlugin(t *testing.T) {
	dest := filepath.Join(t.TempDir(), "elixir.zip")

	if err := buildPluginZip(t.TempDir(), dest); err == nil {
		t.Error("buildPluginZip without metadata.lua succeeded")
	}

	noHooks := t.TempDir()
	writeTestFile(t, noHooks, "metadata.lua", "PLUGIN = {}\n")
	writeTestFile(t, noHooks, "lib/elixir_utils.lua", "return {}\n")
	if err := buildPluginZip(noHooks, dest); err == nil {
		t.Error("buildPluginZip without hooks/ succeeded")
	}

	noLib := t.TempDir()
	writeTestFile(t, noLib, "metadata.lua", "PLUGIN = {}\n")
	writeTestFile(t, noLib, "hooks/available.lua", "function PLUGIN:Available(ctx) return {} end\n")
	if err := buildPluginZip(noLib, dest); err == nil {
		t.Error("buildPluginZip without lib/ succeeded")
	}
}
