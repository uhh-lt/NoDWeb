define ['backbone', 'underscore', 'models/SourceModel', 'models/EntityModel', 'collections/TagsCollection'], (Backbone, _, SourceModel, EntityModel, TagsCollection) ->
	Backbone.Collection.extend
		model: SourceModel
		relationId: null
		url: () ->
			 jsRoutes.controllers.Graphs.clusteredSources(this.relationId, this.date).url
		entities: [new EntityModel(), new EntityModel()]
		tags: new TagsCollection()
		loading: false

		setLoading: (loading) ->
			this.loading = loading;
		
		#Set date
		setDate: (d) ->
			this.date = d
			this.tags.setDate(d)

		setEntities: (entity1, entity2) ->
			this.entities[0].clear().set(entity1)
			this.entities[1].clear().set(entity2)
			
		setTags: (tags) ->
			this.tags.reset()
			this.tags.addMultipleAndSelectPrimary (tags)

			###
			for key, tagsInSentence of tags
				do (tagsInSentence) =>
					this.tags.add(tagsInSentence)
			###
			
		setClusters: (clusters) ->
			for cluster in clusters
				do (cluster) =>
					for sentence in cluster.proxies
						do (sentence) =>
							this.tags.toJSON()
							tags = this.tags.where
								sentence: sentence.sentence.id
							sentence.tags = (new Backbone.Collection(tags)).toJSON()
			
			this.reset clusters