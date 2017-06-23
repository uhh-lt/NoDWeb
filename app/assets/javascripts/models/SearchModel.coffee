define ['backbone', 'moment'], (Backbone, moment) ->
	Backbone.Model.extend
		defaults:
			date: moment().format('DD.MM.YYYY')