package models
import java.sql.Connection

import anorm.SqlParser._
import anorm.JodaParameterMetaData._
import anorm._
import org.joda.time.DateTime
import play.api.Play.current
import play.api.db.DB
import util.{CreateOrGet, Created, Existed}


case class Tag(id: Option[Long], relationshipId: Long, sentenceId: Long, label: String, direction: String, created: DateTime, showOnEgde: Boolean, isSituative: Boolean) {

  def sentence() = Sentence.byId(sentenceId)
  
  def withValues(id: Option[Long] = this.id, relationshipId:Long = this.relationshipId, sentenceId: Long = this.sentenceId,
      label: String = this.label, direction: String = this.direction, created: DateTime = this.created, showOnEdge: Boolean = this.showOnEgde, isSituative: Boolean = this.isSituative) = {

    new Tag(id, relationshipId, sentenceId, label, direction, created, showOnEgde, isSituative)
  }
}


object Tag {

  /**
   * Simple parser for tag result sets.
   */
  val simple = {
    get[Option[Long]]("id")~
    get[Long]("relationship_id")~
    get[Long]("sentence_id")~
    get[String]("label")~
    get[String]("direction")~
    get[DateTime]("created")~
    get[Boolean]("showOnEdge")~
    get[Boolean]("situative") map {
      case id~relationshipId~sentenceId~label~direction~created~showOnEdge~situative=> new Tag(id, relationshipId, sentenceId, label, direction, created, showOnEdge, situative)
    }
  }
  
  def byId(id: Long) = {
    DB.withConnection { implicit connection =>
      SQL"""
        SELECT
          t.id AS id,
          relationship_id,
          sentence_id,
          label,
          direction,
          created,
          showOnEdge,
          situative,
        FROM tags t
        JOIN labels l ON t.label_id = l.id
        WHERE t.id = $id
      """.as(simple.singleOpt)
    }
  }
  
  def byRelationship(relationshipId: Long, excludeDownvoted:Boolean = true) = {
    DB.withConnection { implicit connection =>
      // TODO 'SELECT DISTINCT' here prevents the query from producing tags more than once if mutliple
      // patterns generate them; this would especially need to be altered if directions would be taken into account better
      SQL("""
        SELECT DISTINCT
          t.id AS id,
          t.relationship_id AS relationship_id,
          t.sentence_id AS sentence_id,
          l.label AS label,
          t.direction AS direction,
          t.created AS created,
          t.showOnEdge AS showOnEdge,
          t.situative AS situative
        FROM tags t
        JOIN labels l ON t.label_id = l.id
        WHERE t.relationship_id = {rId}
      """).on(
        'rId -> relationshipId
      ).as(simple.*) groupBy (_.sentenceId)
    }
  }
  
  def byLabel(relationshipId: Long, label: String) = {
    DB.withConnection { implicit connection =>
      SQL"""
        SELECT
          t.id AS id,
          relationship_id,
          sentence_id,
          label,
          direction,
          created,
          showOnEdge,
          situative
        FROM  tags t
        JOIN  labels l ON t.label_id = l.id
        WHERE t.relationship_id = $relationshipId
        AND   l.label = $label
      """.as(simple.*)
    }
  }
  
  def byValues(relationshipId: Long, sentenceId: Long, labelId: Long)(implicit connection: Connection) = {
    SQL"""
      SELECT
        t.id AS id,
        relationship_id,
        sentence_id,
        label,
        direction,
        created,
        showOnEdge,
        situative
      FROM  tags t
      JOIN  labels l ON l.id = t.label_id
      WHERE t.relationship_id = $relationshipId
        AND t.sentence_id = $sentenceId
        AND t.label_id = $labelId
    """.as(simple.singleOpt)
  }

  /**
   * Given a tag, creates it in the database or returns an already existing tag. If a tag was created,
   * Existed(tag) is returned, otherwise the result is Created(tag).
   * 
   * @param tag The tag.
   *
   * @see util.CreateOrGet
   */
  def createOrGet(tag: Tag): CreateOrGet[Tag] = {
    // create new tag or get existing
    val entity: CreateOrGet[Tag] = DB.withTransaction { implicit connection =>
      // get the label id from database (create a new label if it does not exist)
      val labelId = getOrCreateLabel(tag.label)
      
      // get existing tag
      val tagOpt = byValues(tag.relationshipId, tag.sentenceId, labelId)
      
      if (tagOpt.isDefined) {
        Existed(tagOpt.get)
      // otherwise, create a new tag and return it
      } else {
        val id = SQL("""
          INSERT INTO tags
            (relationship_id, sentence_id, label_id, direction, created, showOnEdge, situative)
          VALUES
            ({rId}, {sId}, {lId}, {direction}, DATE({created}), {showOnEdge}, {situative})
        """).on(
          'rId -> tag.relationshipId,
          'sId -> tag.sentenceId,
          'lId -> labelId,
          'direction -> tag.direction,
          'created -> tag.created,
          'showOnEdge -> tag.showOnEgde,
          'situative -> tag.isSituative
        ).executeInsert().get
        Created(tag.withValues(Some(id)))
      }
    }

    entity
  }
  
  def createOrGet(relationshipId: Long, sentenceId: Long, label: String, direction: String, created: DateTime, showOnEdge: Boolean, isSituative: Boolean): CreateOrGet[Tag] = {
    val tag = new Tag(None, relationshipId, sentenceId, label, direction, created, showOnEdge, isSituative)
    createOrGet(tag)
  }
  
  def remove(tagId: Long) = {
    DB.withConnection { implicit connection =>
      SQL"DELETE FROM tags WHERE id = $tagId".execute()
    }
  }
  
  def updateLabel(tagId: Long, label: String) = {
    val labelId = getOrCreateLabel(label)
    DB.withConnection { implicit connection => 
      SQL"UPDATE tags SET label_id = $labelId WHERE id = $tagId".execute()
    }
  }

  def updateVisibility(tagId: Long, isVisible: Boolean) = {
    DB.withConnection { implicit connection =>
      SQL(
        """UPDATE tags
           SET showOnEdge = {visibility}
           WHERE id = {tagId}""").on(
        'tagId -> tagId,
        'visibility ->(if(isVisible) 1 else 0)
      ).execute()
    }
  }
  
  def getOrCreateLabel(label: String) = {
    DB.withTransaction { implicit connection =>
      val idOpt = SQL"SELECT id FROM labels WHERE label = $label".as(get[Long]("id").singleOpt)
      idOpt getOrElse { SQL"INSERT INTO labels (label) VALUES ($label)".executeInsert().get }
    }
  }
}