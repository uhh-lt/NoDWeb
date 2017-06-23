package models

import anorm.SqlParser._
import anorm._
import play.api.Play.current
import play.api.db.DB


case class Sentence(id: Long, text: String)

object Sentence {

  val simple = {
    get[Long]("id")~
    get[String]("sentence") map { case id~sentence => new Sentence(id, sentence) }
  }
  
  def byId(id: Long): Option[Sentence] = {

    DB.withConnection { implicit connection =>
      SQL"SELECT id, sentence FROM sentences WHERE id = $id".as(simple.singleOpt)
    }
  }
}