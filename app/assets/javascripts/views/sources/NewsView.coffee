define ['backbone.marionette', 'hbs!templates/sources/news', 'json2', 'jquery'], (marionette, tpl, JSON, $) ->
	Marionette.ItemView.extend	
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		collection: null
		currentModel: 0
		
		serializeData: () ->
			primarytag = this.collection.tags.getPrimary()
			this.model = this.collection.at this.currentModel
			viewData = 
				loading: this.collection.loading
				cluster: if this.model? then this.model.toJSON() else {}
				collection: this.collection.toJSON()
				clusterIndex: this.currentModel + 1
				clusterCount: this.collection.size()
				entity1: this.collection.entities[0].toJSON()
				entity2: this.collection.entities[1].toJSON()
				relation: this.collection.relationId
				primarytag: primarytag
			
		
		initialize: () ->
			this.listenTo this.collection, 'reset', () =>
				this.currentModel = 0
				this.model = this.collection.first()
				this.render()
			, this
		
		events:
			'click a.next': 'next'
			'click a.prev': 'prev'
			#'click .tag-box > .tag-row': 'toggleDropdown'
			'click .toggle': 'toggleDirection'
			'keydown .tag > .input > input': 'handleTagKeyDown'
			'click .dropdown .set-label-local': 'setLabelLocalInNetwork'
			'click .dropdown .set-label-global': 'setLabelGlobalInNetwork'
			'click input[type=radio].is-situative': 'setLabelLocalInNetwork'
			'click input[type=radio].is-not-situative': 'setLabelGlobalInNetwork'
		
		next: () ->
			this.currentModel = (this.currentModel + 1)%this.collection.size()
			this.render()
		
		prev: () ->
			this.currentModel = if this.currentModel == 0 then this.collection.size() - 1 else this.currentModel - 1
			this.render()
			
		toggleDirection: (e) ->
			e.preventDefault()
			e.stopPropagation()
			el = e.currentTarget;
			tag = $(el).closest('.tag');
			if tag.hasClass 'right'
				if tag.hasClass 'left'
					tag.removeClass 'left'
				else
					tag.removeClass 'right'
					tag.addClass 'left'
			else
				tag.addClass 'right'
			this.hideMenu()
		
		handleTagKeyDown: (e) ->
			if e.keyCode == 13
				e.preventDefault()
				e.stopPropagation()
				el = $(e.currentTarget)
				label = el.val()
				sentence = el.closest('.sentence').attr('data-sentence-id')
				tag = el.closest('.tag')
				direction = if tag.hasClass('left') and tag.hasClass('right') then 'b' else if tag.hasClass('right') then 'r' else 'l'
				el.attr("disabled","disabled")
				isSituative = if tag.find('.is-situative > input:checked').length > 0 then false else true

				if label.replace(/\s+/g, '').length > 0
					this.addTag sentence, label, direction, isSituative, el
				
		addTag: (sentenceId, label, direction, isSituative, el) ->
			if this.collection.tags.where({label: label}).length
				el.shake 3, 7, 800, () ->
					$(this).val ''
					$(this).removeAttr 'disabled'
			else	
				$.getJSON jsRoutes.controllers.Tags.add(this.collection.relationId, sentenceId, label, direction, this.collection.date, isSituative).url, (res) =>
					NotD.vent.trigger 'tagAdded', res
					if isSituative
						this.setLabelLocalInNetwork(null, label)
					else
						this.setLabelGlobalInNetwork(null, label)
					#NotD.vent.trigger 'relationSelected', this.collection.relationId

		toggleDropdown: (e) ->
			e.preventDefault()
			e.stopPropagation()
			$el = $(e.currentTarget)
			$el.children('.dropdown').toggleClass 'open'
			this.hideMenu(e, $el.children('.dropdown'))

		setLabelGlobalInNetwork: (e, label) ->
			label = if label? then label else $(e.currentTarget).closest('.tag-row').find('.caption').text()
			$.get jsRoutes.controllers.Tags.showLabelInNetworkForAllDays(this.collection.relationId, label, this.collection.date).url, (res) =>
				$.getJSON jsRoutes.controllers.Tags.byRelationship(this.collection.relationId).url, (res) =>
					NotD.vent.trigger 'tagsUpdated', res
					NotD.vent.trigger 'relationSelected', this.collection.relationId

		setLabelLocalInNetwork: (e, label) ->
			label = if label? then label else $(e.currentTarget).closest('.tag-row').find('.caption').text()
			$.get jsRoutes.controllers.Tags.showLabelInNetworkForToday(this.collection.relationId, label, this.collection.date).url, (res) =>
				$.getJSON jsRoutes.controllers.Tags.byRelationship(this.collection.relationId).url, (res) =>
					NotD.vent.trigger 'tagsUpdated', res
					NotD.vent.trigger 'relationSelected', this.collection.relationId
		
		hideMenu: (e, $el) ->
			$active = this.$el.find('.dropdown.open');
			if !_.isUndefined($el) then $active = $active.not($el);
			$active.removeClass('open')
				