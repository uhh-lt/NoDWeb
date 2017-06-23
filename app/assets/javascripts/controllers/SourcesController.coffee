define ['jquery', 'underscore', 'backbone.marionette', 'json2', 'collections/NewssourcesCollection', 'collections/TwittersourcesCollection', 'views/sources/IndexView'], ($, _, Marionette, JSON, NewssourcesCollection, TwittersourcesCollection, SourceView) ->
	Marionette.Controller.extend
		initialize: (options) ->
			this.newssources = new NewssourcesCollection()
			this.twittersources = new TwittersourcesCollection()

			this.sourceView = new SourceView {
				newscollection: this.newssources
				twittercollection: this.twittersources
			}
			
			NotD.vent.on 'dateChanged', (date) =>
				this.newssources.setDate(date)
				this.twittersources.setDate(date)
				if this.sourceView?
					this.sourceView.closeSources()
				
			NotD.vent.on 'relationSelected', (relationId) =>
				this.relationSelected relationId
	
			this.newssources.setDate(moment().format('YYYY-MM-DD'))
		
		relationSelected: (relationId) ->
			this.newssources.reset()
			this.newssources.setLoading true
			this.twittersources.setLoading true
			NotD.sourceRegion.show this.sourceView
			this.sourceView.handleShow()
			
			this.newssources.relationId = relationId
			this.twittersources.relationId = relationId
			
			this.newssources.fetch
				success: (collection, response, options) =>
					collection.setLoading false
					collection.setEntities response.entity1, response.entity2
					collection.setTags response.tags
					collection.setClusters response.clusters
					
			this.twittersources.fetch()