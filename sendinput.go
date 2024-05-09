package main

import (
	"log"

	"github.com/micmonay/keybd_event"
)

func PressAnyKey(key ...int) error {
	kb, err := keybd_event.NewKeyBonding()
	if err != nil {
		log.Println(err)
		return err
	}

	// Select keys to be pressed
	kb.SetKeys(key...)

	// Press the selected keys
	if err = kb.Launching(); err != nil {
		log.Println(err)
		return err
	}

	return nil
}
