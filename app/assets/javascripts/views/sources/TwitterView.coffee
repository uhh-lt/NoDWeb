define ['backbone.marionette', 'hbs!templates/sources/twitter', 'json2', 'jquery'], (marionette, tpl, JSON, $) ->
	Marionette.ItemView.extend	
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		collection: null
		currentModel: 0
		
		serializeData: () ->
			entities = this.collection.getEntities()
			entities = entities.map (entity) =>
				msg = this.collection.messagesByEntity(entity).toJSON();
				ret = {
					name: entity
					messagecnt: msg.length
					messages: msg
				}
			
			viewData = 
				entities: entities
				collection: this.collection.toJSON()
				relation: this.collection.relationId
				loading: this.collection.loading
		
		initialize: () ->
			
		
		showLoading: () ->
			#$(this.el).html('<span class="loading fa fa-spin fa-spinner fa-5x"></span>')