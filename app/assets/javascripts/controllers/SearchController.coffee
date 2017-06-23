define ['backbone.marionette', 'models/SearchModel', 'views/search/DateView', 'views/search/FilterView'], (Marionette, SearchModel, DateView, FilterView) ->
	Marionette.Controller.extend
		initialize: (options) ->
			this.searchModel = new SearchModel
			this.dateView = new DateView
				model: this.searchModel
			
			NotD.dateRegion.show this.dateView
			
			this.filterView = new FilterView
				collection: options.linksCollection
			NotD.filterRegion.show this.filterView