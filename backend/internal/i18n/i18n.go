package i18n

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
)

type Translator struct {
	mu       sync.RWMutex
	locales  map[string]map[string]string
	defaultLang string
}

var global *Translator

func Init(localesDir, defaultLang string) error {
	t := &Translator{
		locales:     make(map[string]map[string]string),
		defaultLang: defaultLang,
	}

	entries, err := os.ReadDir(localesDir)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		lang := entry.Name()[:len(entry.Name())-5]
		data, err := os.ReadFile(filepath.Join(localesDir, entry.Name()))
		if err != nil {
			continue
		}
		var messages map[string]string
		if err := json.Unmarshal(data, &messages); err != nil {
			continue
		}
		t.locales[lang] = messages
	}

	global = t
	return nil
}

func T(lang, key string, args ...map[string]string) string {
	if global == nil {
		return key
	}
	return global.t(lang, key, args...)
}

func (t *Translator) t(lang, key string, args ...map[string]string) string {
	t.mu.RLock()
	defer t.mu.RUnlock()

	msgs, ok := t.locales[lang]
	if !ok {
		msgs, ok = t.locales[t.defaultLang]
		if !ok {
			return key
		}
	}

	msg, ok := msgs[key]
	if !ok {
		if t.defaultLang != lang {
			if defaultMsgs, ok := t.locales[t.defaultLang]; ok {
				msg = defaultMsgs[key]
			}
		}
		if msg == "" {
			return key
		}
	}

	if len(args) > 0 {
		for k, v := range args[0] {
			msg = replaceVar(msg, "{{"+k+"}}", v)
		}
	}

	return msg
}

func replaceVar(s, placeholder, value string) string {
	for i := 0; i < len(s); i++ {
		if s[i] == '{' && i+len(placeholder)-1 < len(s) && s[i:i+len(placeholder)] == placeholder {
			return s[:i] + value + s[i+len(placeholder):]
		}
	}
	return s
}

func (t *Translator) Reload(localesDir string) error {
	t.mu.Lock()
	defer t.mu.Unlock()

	entries, err := os.ReadDir(localesDir)
	if err != nil {
		return err
	}

	newLocales := make(map[string]map[string]string)
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		lang := entry.Name()[:len(entry.Name())-5]
		data, err := os.ReadFile(filepath.Join(localesDir, entry.Name()))
		if err != nil {
			continue
		}
		var messages map[string]string
		if err := json.Unmarshal(data, &messages); err != nil {
			continue
		}
		newLocales[lang] = messages
	}
	t.locales = newLocales
	return nil
}

func GetSupportedLanguages() []string {
	if global == nil {
		return []string{"zh", "en"}
	}
	global.mu.RLock()
	defer global.mu.RUnlock()
	langs := make([]string, 0, len(global.locales))
	for lang := range global.locales {
		langs = append(langs, lang)
	}
	return langs
}
