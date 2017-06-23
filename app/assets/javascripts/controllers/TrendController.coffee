define ['jquery', 'underscore', 'backbone.marionette', 'json2', 'views/trend/IndexView', 'collections/TrendwordsCollection'], ($, _, Marionette, JSON, TrendView, TrendwordsCollection) ->
	Marionette.Controller.extend
		initialize: (options) ->
			this.linksCollection = options.linksCollection
			this.collection = new TrendwordsCollection()
			
			this.trendView = new TrendView
				collection: this.collection
			
			NotD.vent.on 'dateChanged', (date) =>
				this.dateSelected date
				
			NotD.vent.on 'nodeSelected', (node) =>
				this.nodeSelected node
				
			NotD.vent.on 'clusterOpen', (clusterId) =>
				this.clusterOpened clusterId
				
			NotD.vent.on 'clusterClose', (clusterId) =>
				this.clusterClosed clusterId
				
			NotD.trendRegion.show this.trendView
			this.trendView.showLoading()
		
		dateSelected: (date) ->
			this.collection.setDate(date)
			
		nodeSelected: (node) ->
			if this.collection.get(node)?
				visible = this.collection.where
					'visible': true
				if visible?
					visible.forEach (model) -> model.set('visible', false)
				this.collection.get(node).set('visible', true)
			else
				this.collection.addSeries node, this.linksCollection.nodes().get(node).get('group')
			
		clusterOpened: (clusterId) ->
			ids = this.linksCollection.nodes().groups().get( clusterId ).get('labels').pluck 'id'
			this.collection.addSeries(ids, clusterId)
			
		clusterClosed: (clusterId) ->
			this.collection.removeCluster(clusterId)