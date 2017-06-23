define ['backbone.marionette', 'hbs!templates/search/date', 'jquery', 'daterangepicker', 'moment'], (marionette, tpl, $, datepicker, moment) ->
	Marionette.ItemView.extend
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		startDate: null
		
		initialize: () ->
			this.startDate = moment().format('YYYY-MM-DD')
			if document.location.search?
				dt = document.location.search.match(/[\?\&]date\=(\d{4}\-\d{2}\-\d{2})/)
				if dt?
					this.startDate = dt[1];
		
			NotD.vent.trigger 'dateChanged', this.startDate
		
		onRender: () ->
			$('.input-group.date input', this.$el).val(moment(this.startDate).format('DD.MM.YYYY'));
			
			$('.input-group.date', this.$el).daterangepicker
				format: "DD.MM.YYYY",
				singleDatePicker: true,
				startDate: moment(this.startDate),
				endDate: moment(this.startDate),
				maxDate: moment().format('DD.MM.YYYY'),
			, (start, end, label) =>
				$('.input-group.date input', this.$el).val(end.format('DD.MM.YYYY'));
				this.handleDateChange(start, end, label)
			
			#ToDo Remove
			###
			$('#data-range-picker').val(moment().subtract(7, 'days').format('DD.MM.YY') + ' - ' + moment().format('DD.MM.YY'))
			$('#data-range-picker').daterangepicker
				format: "DD.MM.YYYY",
				startDate: moment(),
				endDate: moment(),
				maxDate: moment().format('DD.MM.YYYY'),
				ranges: {
					Heute: [1,2]
					Gestern: [1,2]
					'Letzte Woche': [1,2]
					Gesamt: [1,2]
				}
			, (start, end, label) =>
			###
				
						
		handleDateChange: (start, end, label) ->
			date = end.format('YYYY-MM-DD')
			NotD.vent.trigger 'dateChanged', date