package models

import anorm.SqlParser._
import anorm.JodaParameterMetaData._
import anorm._
import org.joda.time.DateTime
import play.api.Play.current
import play.api.db.DB


//TODO Simplify the c'tor timestamps no longer needed. Investigate
case class Relationship(id: Long, e1: Long, e2: Long, frequency: Int, date: Option[DateTime] = None) {

  def entity1 = Entity.byId(e1)
  def entity2 = Entity.byId(e2)

  override def toString = "Relationship(%d, %s, %s)".format(id, entity1, entity2)
}


object Relationship {

  def simple: RowParser[Relationship] = {
    get[Long]("id") ~
      get[Long]("e1") ~
      get[Long]("e2") ~
      get[Int]("frequency") ~
      get[DateTime]("date") map {
      case id ~ e1 ~ e2 ~ frequency ~ date => Relationship(id, e1, e2, frequency, Some(date))
    }
  }

  def byId(id: Long, date: DateTime): Option[Relationship] = {

    DB.withConnection { implicit connection =>
      SQL("""SELECT id, entity1 AS e1, entity2 AS e2, dayFrequency as frequency, date
             FROM relationships r
             WHERE r.id = {id} AND date = DATE({date})""").on(
          'id -> id,
          'date -> date).as(simple.singleOpt)
    }
  }
}