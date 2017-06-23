package util

import org.joda.time.format.DateTimeFormat
import org.joda.time.{DateTime, DateTimeZone, LocalDateTime}


object DateTimeUtil {

  implicit def dateTimeOrdering: Ordering[DateTime] = Ordering.fromLessThan(_ isBefore _)
  
  val clientDateTimeFormatter = DateTimeFormat.forPattern("yyyy-MM-dd")

  /*
   * Converts clientside date strings "YYYY-MM-DD" to a <tt>DateTime</tt>.
   */
  def clientDateStringToDateTime(date: String) =  LocalDateTime.parse(date).toDateTime(DateTimeZone.UTC)
  def clientDateStringToTimestamp(date: String) = clientDateStringToDateTime(date).getMillis()
  def dateTimeToClientDateString(date: DateTime) = date.toString(clientDateTimeFormatter)
  def dayBefore(date: String) = clientDateStringToDateTime(date).minusDays(1)
  
  def isTodayBeforeHour(date: String, hourOfDay: Int): Boolean = {

    val actual = clientDateStringToDateTime(date).toLocalDate
    val expected = DateTime.now().toLocalDate

    actual.isEqual(expected) && DateTime.now().getHourOfDay < hourOfDay
  }
}