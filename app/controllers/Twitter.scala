package controllers

import anorm.SqlParser._
import anorm.JodaParameterMetaData._
import anorm._
import models.{Entity, Tweet}
import org.joda.time.DateTime
import play.api.Play.current
import play.api.db.DB
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}


object Twitter extends Controller {

  private def simple: RowParser[Tweet] = {
    get[Long]("id") ~
      get[DateTime]("created") ~
      get[String]("message") map {
      case id ~ created ~ message => new Tweet(id, created, message)
    }
  }

  def getTweetsForRelationship(relationshipId: Long, date: String) = Action { implicit request =>
    /*val relation = CompleteGraph.relationships(relationshipId)
    val entity1 = CompleteGraph.entities(relation.e1)
    val entity2 = CompleteGraph.entities(relation.e2)
    val dateTime = if(isToday(date)) dayBefore(date) else clientDateStringToDateTime(date)

    val result = Json.obj(entity1.name -> getTweetsAsJson(entity1, dateTime),
      entity2.name -> getTweetsAsJson(entity2, dateTime))
    Ok(result)*/
    Ok("")
  }

  private def getTweetsAsJson(entity: Entity, date: DateTime) = {
    val tweets = retrieveTweets(entity, date, 10)
    Json.arr(tweets.map(Json.toJson(_)))
  }


  private def retrieveTweets(entity: Entity, date: DateTime, limit: Int): List[Tweet] = {
    val id = entity.id
    DB.withConnection("twitter") { implicit connection =>
      SQL"""SELECT t.id, t.created, t.message
            FROM entities e
            INNER JOIN entities_to_tweets et ON e.id = et.entity_id
            INNER JOIN tweets t ON t.id = et.tweet_id
            WHERE t.created = DATE(${date}) AND e.id = ${id}
            LIMIT ${limit}
      """.on(
        ).as(simple.*)
    }
  }
}
