package controllers

import models.{Entity, TrendWords}
import org.joda.time.DateTime
import play.Logger
import play.api.db.DB
import play.api.http.MimeTypes
import play.api.Play.current
import anorm.JodaParameterMetaData._
import anorm.SqlParser._
import anorm._
import play.api.libs.json.Json.toJsFieldJsValueWrapper
import play.api.libs.json.{JsArray, Json}
import play.api.mvc.{Action, Controller}
import util.DateTimeUtil._
import util.JsonExtension.getJsonArray

object TrendChart extends Controller {

  val numTrendWords = 7

  def createTrendChart(date: String) = Action { implicit request =>

    val datetime = if (isTodayBeforeHour(date, 19)) dayBefore(date) else clientDateStringToDateTime(date)
    Logger.debug(s"Showing trend chart for: ${datetime}")

    val trendyWords = TrendWords.getTrendWords(datetime, numTrendWords)
    val series = trendyWords.map(toSeries(_))

    val jsonSeries = series.map { case (id, name, s) => Json.obj("id" -> id, "name" -> name, "data" -> seriesToJson(s))}
    val result = getJsonArray(jsonSeries)
    Ok(result).as(MimeTypes.JSON)
  }

  def addSeries(node: Long) = Action { implicit request =>

    val (id, name, series) = toSeries(node)

    val json = Json.obj("id" -> id, "name" -> name, "data" -> seriesToJson(series))
    Ok(json).as(MimeTypes.JSON)
  }

  private def toSeries(node: Long): (Long, String, List[(Long, Int)]) = {

    val seriesName = Entity.byId(node).name
    val series = TrendWords.getFrequencySeries(node).toMap

    val definitionRange =  DB.withConnection { implicit connection =>
      SQL("SELECT DISTINCT(date) from entities ORDER BY date DESC;").as(get[DateTime]("date").*)
    }.map(_.getMillis)


    val result = definitionRange.sortWith((x, y) => x < y).map { timestamp =>
      val freq = series.getOrElse(timestamp, 0)
      (timestamp, freq)
    }
    (node, seriesName, result)
  }

  private def seriesToJson(series: List[(Long, Int)]): JsArray = {

    val arr = series.map { case (id, freq) => Json.arr(id, if (freq == 0) 0.1 else freq)}
    arr.foldLeft(JsArray())((acc, x) => acc ++ Json.arr(x))
  }
}