define ['backbone', 'underscore', 'async'], (Backbone, _, async) ->
	Backbone.Collection.extend
		model: Backbone.Model
		url: () -> jsRoutes.controllers.TrendChart.createTrendChart(this.date).url
		
		initialize: (models, options) ->
			
		
		setDate: (date) ->
			this.unfetched = []
			this.date = date
			this.fetch
				reset: true
				
		addSeries: (nodes, clusterId) ->
			#Set all models to hidden		
			this.forEach (model) -> 
				model.set 'visible', false
			
			if _.isArray(nodes)
				this._addSeries(node) for node in nodes
			else
				this._addSeries(nodes)
			
			if this.unfetched.length > 0			
				async.map this.unfetched, (node, next) =>
					$.getJSON jsRoutes.controllers.TrendChart.addSeries(node).url, (data) ->
						data.visible = true
						data.cluster = clusterId
						next(null, data)
				, (err, data) =>
					this.unfetched = []
					this.add data
					this.assignLegendIndex()
			else
				this.assignLegendIndex()
		
		removeCluster: (clusterId) ->
			remove = []
			
			this.forEach (model) => 
				cluster = model.get 'cluster'
				if cluster? and cluster == clusterId
					remove.push model
				else if !cluster?
					model.set 'visible', true
		
			this.remove remove
		
		_addSeries: (node) ->
			model = this.get(node)
			if !model?
				if !this.unfetched?
					this.unfetched = []
				this.unfetched.push(node)
			else
				model.set 'visible', true
		
		assignLegendIndex: () ->
			max = this.size()
		
			this.forEach (model, index) -> 
				model.set 'legendIndex',  max - index
		
		parse: (response, options) ->
			ret = []
			response.forEach (word) =>
				#Mark the word as trendy so it will never get removed
				word.trendy = true
				word.visible = true
				ret.push word
			
			ret