package models

import anorm.SqlParser._
import anorm.JodaParameterMetaData._
import anorm._
import org.joda.time.DateTime
import play.api.Play.current
import play.api.db.DB

object TrendWords {

  private def seriesParser = get[DateTime]("date") ~ get[Int]("frequency") map { case d ~ f => (d.getMillis(), f) }

  //TODO: Assign score to trendwords because limit may remove important once
  def getTrendWords(date: DateTime, limit: Int): List[Long] = {

    DB.withConnection { implicit connection =>

      val clusterIdOpt = SQL"""SELECT id FROM clusters WHERE date = DATE($date);""".as(get[Long]("id").singleOpt)
      if(clusterIdOpt.isDefined) SQL"""SELECT entity_id FROM trendwords WHERE cluster_id = ${clusterIdOpt.get} LIMIT ${limit};""".as(get[Long]("entity_id").*) else List()
    }
  }

  def getFrequencySeries(entityId: Long): List[(Long, Int)] = {

    DB.withConnection { implicit connection =>

      SQL"""SELECT date, dayFrequency AS frequency
              FROM entities WHERE id = ${entityId}
              ORDER BY date ASC;""".as(seriesParser.*)
    }
  }
}
