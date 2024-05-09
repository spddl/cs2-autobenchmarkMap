package main

import (
	"errors"
	"log"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/andygrunwald/vdf"
	"golang.org/x/sys/windows/registry"
)

func (c *Container) GetCs2Path() error {
	libraryFoldersPath := filepath.Join(c.SteamPath, "steamapps", "libraryfolders.vdf")

	f, err := os.Open(libraryFoldersPath)
	if err != nil {
		return err
	}
	defer f.Close()

	p := vdf.NewParser(f)
	data, err := p.Parse()
	if err != nil {
		return err
	}

	folders := data["libraryfolders"].(map[string]interface{})
	for _, folderData := range folders {
		entry := folderData.(map[string]interface{})
		folder := entry["path"].(string)

		cs2Path := filepath.Join(folder, "steamapps", "common", "Counter-Strike Global Offensive", "game", "csgo")
		if _, err := os.Stat(cs2Path); err == nil {
			c.Cs2Path = cs2Path
			return nil
		}
	}

	return errors.New("CS2 path not found")
}

func (c *Container) GetSteamPath() error {
	steamKey, err := registry.OpenKey(registry.CURRENT_USER, `SOFTWARE\Valve\Steam`, registry.READ)
	if err != nil {
		log.Println(err)
		return err
	}
	defer steamKey.Close()

	steamPath, _, err := steamKey.GetStringValue("SteamPath")
	if err != nil {
		return err
	}

	c.SteamPath = steamPath
	return nil
}

func (c *Container) startCS(args []string) *exec.Cmd {
	options := append([]string{"-applaunch", "730", "-condebug"}, args...)
	cmd := exec.Command(filepath.Join(c.SteamPath, "steam.exe"), options...)
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	return cmd
}

func (c *Container) WriteFile(path, content string) error {
	if err := os.WriteFile(
		path,
		[]byte(content),
		0644,
	); err != nil {
		log.Println(err)
		return err
	}
	return nil
}
