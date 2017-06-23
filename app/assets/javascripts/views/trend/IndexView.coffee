define ['backbone.marionette', 'hbs!templates/trend/trend', 'jquery', 'highchartsExports'], (marionette, tpl, $, highchartsExports) ->
	Marionette.ItemView.extend	
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		collection: null,
		loaded: null,
		isVisible: false,
		chart: null,
				
		events:
			'click button.close': 'closeSources'
			'click a.next': 'next'
			'click a.prev': 'prev'
		
		initialize: () ->
			$('#btn-show-trend').click () =>
				pos = this.$el.offset().top
				$('html, body').animate({scrollTop: pos}, 'slow')
			
			###	
			$(window).on 'scroll', () =>
				if $(window).scrollTop() + $(window).height() > this.$el.offset().top
					this.isVisible = true
					this.load()
				else
					this.isVisible = false
			###
				
			this.listenTo this.collection, 'reset', () => 
				this.handleReset()
			, this
			
			this.listenTo this.collection, 'add', (model) => 
				this.handleAdd(model)
			, this
			
			this.listenTo this.collection, 'remove', (model) => 
				this.handleRemove(model)
			, this
			
			this.listenTo this.collection, 'change', (model) => 
				this.redraw()
			, this
			
			NotD.vent.on 'relationSelected', (relation) => this.handleSourceShow relation
			NotD.vent.on 'relationUnselected', (relation) => this.handleSourceHide relation
		
		onRender: () ->
			$("#trend").show();
			$("#trend").animate
				height: '300px'

		showLoading: () ->
			$(this.el).html('<span class="loading-nod-logo"></span>')
		
		setDate: (date) ->
			this.date = date
			this.load()
		
		handleAdd: (model) ->
			model.set 'series', this.chart.addSeries(model.toJSON(), false)
			this.redraw()
		
		handleReset: () ->
			this.setData this.collection.toJSON()
			
		handleRemove: (model) ->
			series = model.get 'series'
			if series?
				series.remove()
			this.redraw()
		
		setData: (data) ->
			this.render()

			Highcharts.setOptions(
				lang:
					loading: 'Lade...'
					weekdays: ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag']
					shortMonths: ['Jan', 'Febr', 'März', 'Apr', 'Mai', 'Juni', 'Juli', 'Aug', 'Sept', 'Okt', 'Nov', 'Dez']
			)

			this.chart = new Highcharts.Chart
				chart:
					type: 'spline'
					height: 180
					#backgroundColor: '#f3f3f3'
					zoomType: 'x'
					resetZoomButton:
						position:
							align: 'left'
							y: -5
					renderTo: this.el
				title:
					text: ''
				credits: false
				xAxis:
					type: 'datetime'
					dateTimeLabelFormats:
						day: '%e. %b %Y'
					minTickInterval: 24 * 3600 * 1000
				yAxis:
					title:
						text: 'Häufigkeit'
					type: 'logarithmic'
					min: 0.1
					tickInterval: 0.2
					gridLineWidth: 0
					labels:
						formatter: () -> 
							if this.value == 0.1
								return 0
							else return this.value
				series: data
				legend:
					enabled: true
					layout: 'vertical'
					align: 'left'
					verticalAlign: 'top'
				exporting:
					buttons:
						contextButton:
							enabled: false
						customButton:
							enabled: true
							_titleKey: 'hide_all'
							x: 120
							align: 'left'
							verticalAlign: 'bottom'
							symbolFill: '#f3f3f3'
							hoverSymbolFill: '#779ABF'
							symbol: 'circle'
							onclick: () ->
								#TODO Hide all series
							symbol: "url(./assets/images/hide_all.png)"
							onclick: () =>
								this.toggleVisibility()
				lang:
					hide_all: 'Alle aus-/einblenden'
				tooltip:
					useHTML: true
					formatter: () ->
						actualY = if this.point.y == 0.1 then 0 else this.point.y
						s = '' + Highcharts.dateFormat('%A, %b %e, %Y', this.x) + '<br/>'
						s += '<span style="color:'+this.series.color+'">&#8226;'+this.series.name+'</span>: <b>'+actualY+' '
						return s

			this.collection.at(i).set 'series', series for series, i in this.chart.series

			this.addPlotLineForHistoricalDate()
		
		redraw: _.debounce(() ->
			#Update visibility
			this.collection.forEach (model) ->
				series = model.get 'series'
				if series?
					series.update
						visible: model.get 'visible'
						legendIndex: model.get 'legendIndex'
					, false
			#redraw
			this.chart.redraw()
		, 500)

		addPlotLineForHistoricalDate: () ->
			now = moment().startOf('day')

			if moment(this.collection.date).startOf('day').isBefore(now)
				chart = $(this.el).highcharts()
				chart.xAxis[0].addPlotLine(
					id: 'plotline'
					color: 'red'
					value: moment(this.collection.date)
					width: 5
				)
		
		toggleVisibility: () ->
			if this.collection.findWhere({'visible': true})?
				this.collection.forEach (model) ->
					model.set 'visible', false
			else
				this.collection.forEach (model) ->
					model.set 'visible', true
					
		handleSourceShow: () ->
			width = this.$el.width() - 270
			this.chart.setSize(width, this.chart.height, doAnimation = true)
			
		handleSourceHide: () ->
			width = this.$el.width()
			this.chart.setSize(width, this.chart.height, doAnimation = true)