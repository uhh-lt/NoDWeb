import play.api.{Application, GlobalSettings}
import util.LocaleUtils

/**
 * Instance of GlobalSettings that is used to configure Play application behaviour.
 */
object Global extends GlobalSettings {

  override def onStart(app: Application) {

    LocaleUtils.setDefaultLocale()
  }
}
