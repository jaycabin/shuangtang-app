package middleware

import (
	"github.com/gin-gonic/gin"
)

const (
	LangKey = "lang"
)

func I18n() gin.HandlerFunc {
	return func(c *gin.Context) {
		lang := c.GetHeader("Accept-Language")
		if lang == "" {
			lang = "zh"
		}
		if lang != "en" && lang != "zh" {
			lang = "zh"
		}
		c.Set(LangKey, lang)
		c.Next()
	}
}

func GetLang(c *gin.Context) string {
	lang, _ := c.Get(LangKey)
	if lang == nil {
		return "zh"
	}
	return lang.(string)
}
