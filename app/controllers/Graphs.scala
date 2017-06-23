package controllers

import anorm._
import anorm.JodaParameterMetaData._
import models.{Entity, EntityType, Organization, Person, Relationship, Sentence, Source, SourceClusteringMCL, Tag}
import org.joda.time.DateTime
import play.Logger
import play.api.Play.current
import play.api.db.DB
import play.api.http.MimeTypes
import play.api.libs.functional.syntax._
import play.api.libs.json.Json.toJsFieldJsValueWrapper
import play.api.libs.json.Writes.{JsValueWrites, LongWrites, StringWrites, arrayWrites, mapWrites, traversableWrites}
import play.api.libs.json.{Format, JsArray, Json, __}
import play.api.mvc.{Action, Controller}
import util.DateTimeUtil._

import scala.Array.canBuildFrom
import scala.Option.option2Iterable

object Graphs extends Controller {

  val emptyCluster = Json.obj("nodes" -> JsArray(), "links" -> JsArray(), "groups" -> JsArray())

  implicit def entityFormat: Format[Entity] = (
    (__ \ "id").format[Long] and
    (__ \ "type").format[Int] and
    (__ \ "name").format[String] and
    (__ \ "freq").format[Int])(
    (id, entityType, name, frequency) => EntityType(entityType) match {
      case EntityType.Person => new Person(Some(id), name, frequency)
      case EntityType.Organization => new Organization(Some(id), name, frequency)
    },
    (e: Entity) => (e.id.get, e.entityType.id, e.name, e.frequency)
  )
  
  import controllers.Tags.tagFormat
  
  implicit val relationshipFormat: Format[Relationship] = (
    (__ \ "id").format[Long] and
    (__ \ "source").format[Long] and
    (__ \ "target").format[Long] and
    (__ \ "freq").format[Int] and
    (__ \ "tags").format[List[Tag]]
  )(
    (id: Long, e1: Long, e2: Long, freq: Int, _) => new Relationship(id, e1, e2, freq),
    (r: Relationship) => (r.id, r.e1, r.e2, r.frequency, Tag.byRelationship(r.id).values.toList.flatten)
  )

  
  implicit val sourceFormat: Format[Source] = (
    (__ \ "id").format[Long] and
    (__ \ "sentence").format(
      ((__ \ "id").format[Long] and
        (__ \ "text").format[String])
        ((id: Long, text: String) => new Sentence(id, text),
          (s: Sentence) => (s.id, s.text))) and
      (__ \ "source").format[String] and
      (__ \ "date").format[String])(
        (id: Long, sentence: Sentence, source: String, date: String) => new Source(Some(id), sentence, source, DateTime.parse(date)),
        (s: Source) => (s.id.get, s.sentence, s.source, s.formattedDate))


  def clusterGraph(date: String) = Action {implicit request =>

    val datetime = if (isTodayBeforeHour(date, 19)) dayBefore(date) else clientDateStringToDateTime(date)
    Logger.debug(s"Showing clustered graph for: ${datetime}")

    DB.withConnection { implicit c =>

      val json: Option[String] = SQL("""SELECT json
                                        FROM clusters c
                                        WHERE c.date = DATE({searchdate});""").on('searchdate -> datetime).as(SqlParser.str("json").singleOpt)

      if(json.isDefined) Ok(Json.parse(json.get)).as(MimeTypes.JSON) else Ok(emptyCluster).as(MimeTypes.JSON)
    }
  }


  def clusteredSources(relationshipId: Long, date: String, limit: Boolean = true) = Action { implicit request =>
    import util.UpList._

    val datetime = if (isTodayBeforeHour(date, 19)) dayBefore(date) else clientDateStringToDateTime(date)
    val relationship = Relationship.byId(relationshipId, datetime).get

    // get and possibly sample sources
    val sources = Source.byRelationship(relationshipId, datetime)
    val sentenceIds = (sources map { _.sentence.id }).toSet
    val sampled = if (sources.size > 100 && limit) sources.sample(100) else sources

    println(sentenceIds)
    val uniqueSamples = Source.removeSimilarSources(sampled)
    // cluster selected sources
    val clusters = if (uniqueSamples.size > 1)
      (SourceClusteringMCL.cluster(uniqueSamples, pGamma = 1.2))
    else oneClusterPerSource(uniqueSamples)
        
    // get tags associated with the sentences
    val tags = Tag.byRelationship(relationshipId)

    val json = Json.obj(
      "entity1" -> relationship.entity1,
      "entity2" -> relationship.entity2,
      "clusters" -> (clusters map { cluster =>
        val (proxies, rest) = splitCluster(cluster, relationship.entity1, relationship.entity2, tags)
        Json.obj(
          "proxies" -> proxies,
          "rest" -> rest)
      }),
      "tags" -> (tags map { case (key, value) => key.toString -> value }),
      "numClusters" -> clusters.size,
      "numSources" -> sampled.size,
      "numAllSources" -> sources.size)
            
    Ok(json).as(MimeTypes.JSON)
  }

  /*
   * Splits a cluster into up to three representants and the rest. Representants are selected as follows:
   * The first is the earliest in the cluster, the second is a sentence that might heuristically be good
   * for pattern generation, the third is a sentence that contains an automatically generated, but not yet
   * validated tag. Representants are displayed on the client directly, while the rest is initially hidden
   * from the user.
   */
  private def splitCluster(cluster: List[Source], e1: Entity, e2: Entity, tags: Map[Long, List[Tag]]) = {
    val pattern = """%s \S+ \S+( \S+)? %s"""
    if (cluster.size > 3) {
      val name1 = e1.name
      val name2 = e2.name

      val earliest = Some(cluster.head)
      val prettiest = cluster.find { source =>
        source != earliest.get &&
          (pattern.format(name1, name2).r.findFirstIn(source.sentence.text).size > 0 ||
            pattern.format(name2, name1).r.findFirstIn(source.sentence.text).size > 0)
      }
      val tagged = cluster find { source =>
        source != earliest.get && source != prettiest.getOrElse(null) && tags.contains(source.sentence.id)
      }

      val proxies = List(earliest, prettiest, tagged).flatten
      val rest = cluster filter { source => !proxies.contains(source) }
      val missing = 3 - proxies.length

      (proxies ++ (rest take missing), rest drop missing)
    } else (cluster, List[Source]())
  }

  /*
   * Clusters every sentence into its own cluster.
   */
  private def oneClusterPerSource(sources: List[Source]) = sources.map { source => List(source) }.toArray
}