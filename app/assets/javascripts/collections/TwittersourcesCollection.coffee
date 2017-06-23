define ['backbone', 'underscore', 'models/TwitterModel'], (Backbone, _, TwitterModel) ->
	Backbone.Collection.extend
		model: TwitterModel
		relationId: null
		url: () ->
			 jsRoutes.controllers.Twitter.getTweetsForRelationship(this.relationId, this.date).url
		loading: false
		entities: []

		setLoading: (loading) ->
			this.loading = loading;
		
		#Set date
		setDate: (d) ->
			this.date = d
		
		getEntities: () ->
			return this.entities;
			
		messagesByEntity: (entity) ->
			return new Backbone.Collection(this.where
				entity: entity
			)
		
		parse: (response, options) ->
			ret = []
			this.entities = []
			
			for entity, messagecontainers of response
				this.entities.push(entity)
				messagecontainers.forEach (messagecontainer) ->
					messagecontainer.forEach (message) ->
						message.entity = entity
						ret.push message
						isFirst = false;
			ret