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
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// pluginFiles lists the files of the plugin under repoRoot that go into the
// zip, as slash-separated paths relative to repoRoot: metadata.lua, and the Lua
// files directly under hooks/ and lib/. Tests, assets and the rest of the
// repository are not part of the plugin. The hooks directory must hold at least
// one Lua file.
func pluginFiles(repoRoot string) ([]string, error) {
	if !pathExists(filepath.Join(repoRoot, "metadata.lua")) {
		return nil, fmt.Errorf("no metadata.lua under %s", repoRoot)
	}

	files := []string{"metadata.lua"}
	for _, dir := range []string{"hooks", "lib"} {
		entries, err := os.ReadDir(filepath.Join(repoRoot, dir))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", dir, err)
		}
		found := 0
		for _, entry := range entries {
			if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".lua") {
				continue
			}
			files = append(files, dir+"/"+entry.Name())
			found++
		}
		if dir == "hooks" && found == 0 {
			return nil, fmt.Errorf("no Lua hooks under %s", filepath.Join(repoRoot, dir))
		}
	}
	slices.Sort(files)
	return files, nil
}

// buildPluginZip packs the plugin under repoRoot into a zip file at dest. The
// entries sit at the root of the zip, which is how vfox add reads a local zip.
func buildPluginZip(repoRoot, dest string) (err error) {
	files, err := pluginFiles(repoRoot)
	if err != nil {
		return err
	}

	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer func() {
		if closeErr := out.Close(); err == nil {
			err = closeErr
		}
	}()

	zw := zip.NewWriter(out)
	for _, name := range files {
		src := filepath.Join(repoRoot, filepath.FromSlash(name))
		if err := addZipEntry(zw, src, name); err != nil {
			_ = zw.Close()
			return fmt.Errorf("pack %s: %w", name, err)
		}
	}
	return zw.Close()
}

// addZipEntry writes the file src into zw as the entry name.
func addZipEntry(zw *zip.Writer, src, name string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer func() { _ = in.Close() }()

	info, err := in.Stat()
	if err != nil {
		return err
	}
	header := &zip.FileHeader{Name: name, Method: zip.Deflate, Modified: info.ModTime()}
	header.SetMode(0o644)
	w, err := zw.CreateHeader(header)
	if err != nil {
		return err
	}
	_, err = io.Copy(w, in)
	return err
}
