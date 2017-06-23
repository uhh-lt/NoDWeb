package util

import java.util.Locale

object LocaleUtils {

  def setDefaultLocale() = {

    val locale = new Locale.Builder().setLanguage("en").setRegion("US").build()
    Locale.setDefault(locale)
  }
}
