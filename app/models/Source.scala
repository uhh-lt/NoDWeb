package models

import anorm.SqlParser._
import anorm.JodaParameterMetaData._
import anorm._
import org.joda.time.DateTime
import org.joda.time.format.DateTimeFormat
import play.api.Play.current
import play.api.db.DB
import util.UpString._

/**
 * Object representation of sources.
 * 
 * @param id Unique id and primary key.
 * @param sentences The sentence for this source.
 * @param source The source (can be a URL or some form of name of a newspaper issue).
 * @param date Publication date.
 */
case class Source(id: Option[Long] = None, sentence: Sentence, source: String, date: DateTime) extends Ordered[Source] {
  
  val formattedDate = DateTimeFormat.fullDate().print(date)
  
  // compares dates; if dates are equal, subsequently compares ids of the source and its sentence
  // to prevent different sources on the same date or different sentences with the same source from
  // being understood as equal.
  // NOTE this is actually required for clustering; MCL misbehaves otherwise.
  override def compare(that: Source) = {
    val c = this.date.compareTo(that.date)
    if (c != 0) c else {
      val d = id.get.compareTo(that.id.get)
      if (d != 0) d else { sentence.id.compareTo(that.sentence.id)}
    }
  }
  
  def ToStemsWithoutStopwords = sentence.text.stemsWithoutStopwords
}

/**
 * Companion object and DAO for sources.
 */
object Source {
  
  /**
   * Simple parser for source result sets.
   */
  def simple = {
    get[Option[Long]]("id")~
    get[Long]("sentence_id")~
    get[String]("sentence")~
    get[String]("source")~
    get[DateTime]("date") map {
      case id~sid~sentence~source~date => new Source(id, new Sentence(sid, sentence), source, date)
    }
  }
  
  def removeSimilarSources(sources: List[Source]): List[Source] = sources match {
    case Nil => sources
    case x::xs => {
      val similar = xs.filter { l => 
        jaccardCoefficient(x.ToStemsWithoutStopwords.toSet, l.ToStemsWithoutStopwords.toSet) >= 0.8
      }
      if(similar.isEmpty) x :: removeSimilarSources(xs) else removeSimilarSources(xs)
    }
  }
  
  //TODO Move to util
  private def jaccardCoefficient(a: Set[String], b: Set[String]) = {
    (a & b).size /  a.union(b).size
  }
    
  def byRelationship(relationshipId: Long, date: DateTime) = {

    DB.withConnection { implicit connection =>
      SQL"""
        SELECT DISTINCT so.id AS id,
	              s.id AS sentence_id, 
	              s.sentence AS sentence, 
	              so.source AS source, 
	              so.date AS date 
        FROM sentences s, sentences_to_sources AS s2s, sources so, relationships_to_sentences r2s 
        WHERE r2s.relationship_id = $relationshipId
              AND r2s.sentence_id = s.id 
              AND s.id = s2s.sentence_id 
              AND s2s.source_id = so.id
              AND so.date = DATE($date)
        GROUP BY sentence_id
        ORDER BY date ASC
        """.as(simple.*)
      }
    }
}