package models

import anorm.SqlParser._
import anorm._
import play.api.Play.current
import play.api.db.DB


abstract class Entity(val entityType: EntityType.Value) {

  /**
   * The unique id (which is also the primary key in the database) of the entity.
   */
  def id: Option[Long]

  /**
   * The entity name.
   */
  def name: String

  def frequency: Int

  def isPerson = entityType == EntityType.Person
  def isOrganization = entityType == EntityType.Organization
  def typeString = {
    if (isPerson) "PERSON" else "ORGANIZATION"
  }
}

/**
 * The entity type (<tt>Person</tt> or <tt>Organization</tt>).
 */
object EntityType extends Enumeration {

  val Person = Value
  val Organization = Value
}

/**
 * Object representation of a person.
 */
case class Person(val id: Option[Long] = None, val name: String, val frequency: Int) extends Entity(EntityType.Person)

/**
 * Object representation of an organization.
 */
case class Organization(val id: Option[Long] = None, val name: String, val frequency: Int) extends Entity(EntityType.Organization)

/**
 * Companion object and DAO for entities.
 */
object Entity extends {

  /**
   * Parser for entity result sets.
   */
  def simple: RowParser[Entity] = {
    get[Option[Long]]("id") ~
      get[Int]("type") ~
      get[String]("name") ~
      get[Int]("frequency") map {
        case id ~ 0 ~ name ~ frequency => new Person(id, name, frequency)
        case id ~ 1 ~ name ~ frequency => new Organization(id, name, frequency)
      }
  }

  def byId(id: Long) = {
    DB.withConnection { implicit connection =>
      SQL"""
          SELECT id, type, name, dayFrequency as frequency  FROM entities
          WHERE id = $id
          ORDER BY date DESC
          LIMIT 1
        """.as(simple.single)
    }
  }
}