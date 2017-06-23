package controllers

import models.Tag
import play.Logger
import play.api.http.MimeTypes
import play.api.libs.functional.syntax._
import play.api.libs.json.Writes._
import play.api.libs.json.{ Format, Json, __}
import play.api.mvc.{ Action, Controller }
import util.DateTimeUtil.{ clientDateStringToDateTime, clientDateTimeFormatter }


object Tags extends Controller {

  implicit val tagFormat: Format[Tag] = (
    (__ \ "id").format[Long] and
    (__ \ "relationship").format[Long] and
    (__ \ "sentence").format[Long] and
    (__ \ "label").format[String] and
    (__ \ "direction").format[String] and
    (__ \ "created").format[String] and
    (__ \ "showOnEdge").format[Boolean] and
    (__ \ "isSituative").format[Boolean] and
    (__ \ "hasPositive").format[Boolean]
  )(
    (id: Long, relationshipId: Long, sentenceId: Long, label: String, direction: String, created: String, showOnEdge: Boolean, isSituative: Boolean, _) => new Tag(Some(id), relationshipId, sentenceId, label, direction, clientDateStringToDateTime(created), showOnEdge, isSituative),
    (t: Tag) => (t.id.get, t.relationshipId, t.sentenceId, t.label, t.direction, t.created.toString(clientDateTimeFormatter), t.showOnEgde, t.isSituative, false)
  )
  
  //
  // Routes
  //
  
  /**
   * Adds a new tag to a releationship and a sentence (both are needed since a sentence may contain several relationships),
   * a label and a direction.
   */
  def add(relationshipId: Long, sentenceId: Long, label: String, direction: String, created: String, isSituative: Boolean) = Action { implicit request =>
    Logger.debug("Adding tag: %s (sentence = %d, relationship = %d, date: = %s)".format(label, sentenceId, relationshipId, created))
    val result = Tag.createOrGet(relationshipId, sentenceId, label, direction, clientDateStringToDateTime(created), false, isSituative)
    result match {
      case util.Created(tag) =>
        Ok(Json.toJson(tag)).as(MimeTypes.JSON)
      case util.Existed(tag) =>
        Ok
    }
  }
  
  /**
   * Removoes a tag given its id.
   */
  def remove(tagId: Long) = Action {
    Tag.byId(tagId) foreach { tag =>

        Logger.debug("Removing tag: %s".format(tag))
        Tag.remove(tagId)
    }
    Ok
  }

  def showLabelInNetworkForAllDays(relationshipId: Long, label: String, date: String) = Action { implicit request =>
    val dateTime = clientDateStringToDateTime(date)
    val predicate = (t: Tag) => !t.isSituative ||  t.created.isEqual(dateTime)

    changeLabelVisibility(relationshipId, label, predicate)
    Ok
  }

  def showLabelInNetworkForToday(relationshipId: Long, label: String, date: String) = Action { implicit request =>
    val dateTime = clientDateStringToDateTime(date)
    val predicate = (t: Tag) => t.isSituative && t.created.isEqual(dateTime)

    changeLabelVisibility(relationshipId, label, predicate)
    Ok
  }

  private def changeLabelVisibility(relationshipId: Long, label: String, predicate: Tag => Boolean) = {
    Tag.byRelationship(relationshipId) foreach { case(_, tags) =>
        tags foreach { tag => if(predicate(tag)) Tag.updateVisibility(tag.id.get, false) }
    }

    Tag.byLabel(relationshipId, label) foreach { tag =>
      Tag.updateVisibility(tag.id.get, true)
    }
  }
  
  /**
   * For a given relationship, retrieves a <tt>Map</tt> mapping sentence ids to the tags that
   * have been assigned to the respective sentence.
   */
  def byRelationship(relationshipId: Long) = Action {
    val sentences2tags = Tag.byRelationship(relationshipId) map {
      case (key, value) => key.toString -> value
    }
    Ok(Json.toJson(sentences2tags)).as(MimeTypes.JSON)
  }
  
  /**
   * For a list of relationship, retrieves a <tt>Map</tt> mapping sentence ids to the tags that
   * have been assigned to the respective sentence.
   * TODO: Use a single query
   */
  def byRelationships(relationshipIds: String) = Action {
    val tags = relationshipIds.split(",").map(relationshipId => 
      	Tag.byRelationship(relationshipId.toLong).map {
    		case (key, value) => key.toString -> value
    	})
    
    Ok(Json.toJson(tags)).as(MimeTypes.JSON)
  }
}