package controllers

import play.api.Logger
import play.api.mvc.{Action, Controller}

import scala.util.Random

object Application extends Controller {

  /**
   * Serves the Networks of Names frontend to the client.
   */
  def index = Action { implicit request =>
    // assign the user a UID (used to associate action logs with user sessions)
    val uid = request.session.get("uid").getOrElse { (Random.alphanumeric take 8).mkString }
    Logger.debug("Session UID: " + uid)
    // show main page
    Ok(views.html.index()).withSession("uid" -> uid)
  }


  def javascriptRoutes = Action { implicit request =>
    //Note: feature warning is produced by play itself
    import play.api.routing._

    Ok(
      JavaScriptReverseRouter("jsRoutes")(
        controllers.routes.javascript.Graphs.clusterGraph,
        controllers.routes.javascript.Graphs.clusteredSources,
        controllers.routes.javascript.Twitter.getTweetsForRelationship,
        controllers.routes.javascript.TrendChart.createTrendChart,
        controllers.routes.javascript.Tags.add,
        controllers.routes.javascript.Tags.remove,
        controllers.routes.javascript.Tags.byRelationship,
        controllers.routes.javascript.Tags.showLabelInNetworkForAllDays,
        controllers.routes.javascript.Tags.showLabelInNetworkForToday,
        controllers.routes.javascript.Tags.byRelationships,
        controllers.routes.javascript.TrendChart.addSeries
      )
    ).as("text/javascript")
  }
}
