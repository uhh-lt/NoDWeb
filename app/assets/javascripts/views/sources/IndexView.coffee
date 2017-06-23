define ['backbone.marionette', 'hbs!templates/sources/source', 'json2', 'jquery', 'views/sources/NewsView', 'views/sources/TwitterView'], (marionette, tpl, JSON, $, NewsView, TwitterView) ->
	Marionette.LayoutView.extend	
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		regions:
			sourceregion: '.source-region'
		newscollection: null
		twittercollection: null
		
		initialize: (args) ->
			this.newscollection = args.newscollection
			this.twittercollection = args.twittercollection
			NotD.vent.on 'relationUnselected', (relation) => this.closeSources()
		
		events:
			'click button.close': 'handleClose'
			'click .source-select .news': 'showNews'
			'click .source-select .twitter': 'showTwitter'
		
		handleShow: () ->
			$("#sources").show();
			$("#sources").animate
				width: '320px'
			, 300
			this.showNews()
		
		handleClose: () ->
			NotD.vent.trigger 'relationUnselected', this.newscollection.relationId
		
		closeSources: () ->
			$("#sources").animate
				width: '0px'
			, () ->
				$("#sources").hide()
		

		showLoading: () ->
			$(this.el).html('<span class="loading-nod-logo"></span>')

		showNews: () ->
			$('.source-select li.active', this.$el).removeClass('active')
			$('.source-select li .news', this.$el).closest('li').addClass('active')
		
			this.sourceregion.show(new NewsView(
				collection: this.newscollection
			))
			
		showTwitter: () ->
			$('.source-select li.active', this.$el).removeClass('active')
			$('.source-select li .twitter', this.$el).closest('li').addClass('active')
			
			this.sourceregion.show(new TwitterView(
				collection: this.twittercollection
			))		
