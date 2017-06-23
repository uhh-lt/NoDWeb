package models

import org.joda.time.DateTime
import org.joda.time.format.DateTimeFormat
import play.api.libs.functional.syntax._
import util.UpString._
import play.api.libs.json.{JsPath, Reads, _}

case class Tweet(id: Long, date: DateTime, message: String) {
  def cleanToken() = {
    val token = message.tokensWithoutStopwords().toSet

    val filterPredicate = (token: String) => !token.startsWith("http") && !isOnlyDigitToken(token)
    token.filter(filterPredicate)
  }

  private def isOnlyDigitToken(token: String) = token forall Character.isDigit
}

object Tweet {
  //parsing RFC 2822 date format
  val format = DateTimeFormat.forPattern("EEE MMM dd HH:mm:ss Z yyyy")

  implicit val tweetReads: Reads[Tweet] = (
    (JsPath \ 'id).read[Long] ~
      (JsPath \ 'created_at).read[String].map(format.parseDateTime(_)) ~
        (JsPath \ 'text).read[String].map(cleanTweet(_))
    )(Tweet(_, _, _))

  implicit val tweetWrites: Writes[Tweet] = (
    (__ \ "id").write[Long] ~
      (__ \ "date").write[DateTime] ~
      (__ \ "message").write[String]
    )(unlift(Tweet.unapply))

  //TODO: Write tsv writer that supports delimiter escaping (use in twitter and newspaper import)
  private def cleanTweet(text: String) = text.removeNewline().replace("\t", "").unescapeHtml()
}