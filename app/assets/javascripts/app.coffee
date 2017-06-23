define ['backbone', 'backbone.marionette', 'marionette.handlebars', 'controllers/NetworkController', 'controllers/SearchController', 'controllers/SourcesController', 'controllers/TrendController'], (Backbone, Marionette,  MarionetteHandlebars, NetworkController, SearchController, SourcesController, TrendController) ->
	App = new Marionette.Application();
	
	App.addInitializer (options) ->
		this.addRegions {
			networkRegion: options.regionNetwork
			sourceRegion: options.regionSource
			dateRegion: options.regionDate
			trendRegion: options.regionTrend
			filterRegion: options.regionFilter
		}
		this.networkController = new NetworkController()
		this.sourcesController = new SourcesController()
		this.trendController = new TrendController
			linksCollection: this.networkController.linksCollection
		this.searchController = new SearchController
			linksCollection: this.networkController.linksCollection
	
	App.on 'initialize:after', () ->
		Backbone.history.start()