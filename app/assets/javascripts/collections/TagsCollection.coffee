define ['backbone', 'underscore', 'models/TagModel'], (Backbone, _, TagModel) ->
	Backbone.Collection.extend
		model: TagModel
		url: () -> jsRoutes.controllers.Tags.byRelationships( this.linksToLoad.join(',') ).url
		linksToLoad: []
		byRelationship: {}
		
		initialize: (models, options) ->
			if options?
				this.listenTo options.linksCollection, 'reset', this.updateLinks, this
		
		addAndSelectPrimary: (tag) ->
			t = this.get(tag.id)
			
			if t?
				tag = _.defaults tag, t.toJSON()
			
			this.add this.selectPrimaryTag(tag), 
				merge: true
				
		addMultipleAndSelectPrimary: (tags) ->
			ret = []
			
			if !this.byRelationship?
				this.byRelationship = []
			
			for sentenceid, tagsInSentence of tags
				tagsInSentence.forEach (tag) =>
					if this.byRelationship[tag.relationship]?
						this.byRelationship[tag.relationship] = null
			
			for sentenceid, tagsInSentence of tags
				tagsInSentence.forEach (tag) =>
					tag.isPrimary = false
					tag = this.selectPrimaryTag(tag)
					
					ret.push(tag)
			
			this.add ret,
				merge: true
		
		getPrimary: () ->
			primary = this.toJSON().filter (tag) ->
				tag.isPrimary? && tag.isPrimary
			
			console.log primary
			
			if primary?
				primary.shift()
			else
				null
		
		setDate: (d) ->
			this.date = d
		
		updateLinks: (linksCollection) ->
			linkids = linksCollection.pluck 'id'
		
			this.linksToLoad = _.filter linkids, (id) => if this.get(id)? then false else true
			
			if this.linksToLoad.length > 0
				this.fetch()
		
		showTagOnEdge: (tag) ->
			#only tags which are local for the current date or global tags for which the user selected "setGlobal" should be shown on the edges
			#console.log tag.label, tag.isSituative, tag.created, this.date, tag
			
			if ( tag.showOnEdge and ( !tag.isSituative or tag.created == this.date ) )
				true
			else
				false
		
		selectPrimaryTag: (tag) ->
			if !this.byRelationship?
				this.byRelationship = []
			
			if !this.byRelationship[tag.relationship]?
				#there is no primary tag for this relationship
				if this.showTagOnEdge(tag)
					tag.isPrimary = true
					this.byRelationship[tag.relationship] = tag
			else				
				#there is already a primary tag for this relationship
				if this.showTagOnEdge(tag)
					#the new tag is also a candidate for the primary tag
					#only use the new tag if it is local and the current tag is global
					pTag = this.byRelationship[tag.relationship]
					pTagC = pTag
					if this.get(pTag.id)?
						pTagC = this.get(pTag.id).toJSON()

					if ( tag.isSituative and !pTagC.isSituative )
						pTagC.isPrimary = false
						pTag.isPrimary = false
						tag.isPrimary = true
						this.byRelationship[tag.relationship] = tag
			tag
		
		parse: (response, options) ->
			ret = []
			
			if !this.byRelationship?
				this.byRelationship = []
			
			response.forEach (tags) =>
				if !_.isEmpty tags
					for sentenceid, tagsInSentence of tags
						tagsInSentence.forEach (tag) =>
							if this.byRelationship[tag.relationship]?
								this.byRelationship[tag.relationship] = null
			
			response.forEach (tags) =>
				if !_.isEmpty tags
					for sentenceid, tagsInSentence of tags
						tagsInSentence.forEach (tag) =>
							tag = this.selectPrimaryTag(tag)
							
							ret.push(tag)
			ret