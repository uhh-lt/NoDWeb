define ['backbone.marionette', 'hbs!templates/search/filter', 'jquery', 'bootstrap', 'bootstrap3-typeahead', 'jquery-shake'], (marionette, tpl, $, bootstrap, typeahead, shake) ->
	Marionette.ItemView.extend
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		
		events:
			'keydown input': 'handleKeydown'
		
		initialize: (options) ->
			this.listenTo this.collection, 'reset', this.handleCollectionChange, this
		
		onRender: () ->
			this.$el.hide()
			this.$el.find('input').typeahead
				source: (query, process) =>
					data = this.collection.nodes().filter (node) ->
						if node.get('name').toLowerCase().match query.toLowerCase()
							true
						else
							false
					data.map (node) ->
						node.get('name')
				updater: (item) =>
					this.showItem item
					return item
		
		showItem: (name) ->
			node = this.collection.nodes().where
				name: name
			if node? && node.length > 0
				$input = this.$el.find('input')
				$input.attr 'disabled', 'disabled'
				NotD.vent.trigger 'showNode', node.shift().get('id'), true
				window.setTimeout () =>
					$input.val ''
					$input.removeAttr 'disabled'
				, 1000
			else
				$input = this.$el.find('input')
				$input.attr 'disabled', 'disabled'
				$input.shake 3, 7, 800, () ->
					$(this).val ''
					$(this).removeAttr 'disabled'
					
		handleCollectionChange: () ->
			if this.collection.size() > 0
				this.$el.fadeIn()
			else
				this.$el.hide()
				
		handleKeydown: (e) ->
			if e.keyCode == 13
				e.preventDefault()
				e.stopPropagation()
				
				this.showItem this.$el.find('input').val()
