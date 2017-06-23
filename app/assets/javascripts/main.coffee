require.config
	baseUrl: './assets/javascripts'
	paths:
		hbs : 'libs/handlebars/hbs'
		Handlebars : 'libs/handlebars/handlebars'
		backbone : 'libs/marionette/backbone'
		underscore : 'libs/marionette/underscore'
		jquery : 'libs/marionette/jquery'
		'backbone.marionette' : 'libs/marionette/backbone.marionette.min'
		socketio: '../socket.io/socket.io'
		i18nprecompile : 'libs/handlebars/i18nprecompile'
		json2 : 'libs/handlebars/json2'
		'marionette.handlebars' : 'libs/handlebars/backbone.marionette.handlebars'
		'bootstrap' : 'libs/bootstrap/bootstrap.min'
		moment : 'libs/moment/moment.min'
		hyphenate : 'libs/hyphenate'
		d3: 'libs/d3/d3.v3.min',
		datepicker: 'libs/bootstrap-datepicker/bootstrap-datepicker'
		daterangepicker: 'libs/bootstrap-daterangepicker/daterangepicker'
		'bootstrap3-typeahead': 'libs/bootstrap-typeahead/bootstrap-typeahead.min'
		'jquery-shake': 'libs/jquery-shake/jquery-shake'
		cola: 'libs/cola/cola',
		highcharts: 'libs/highcharts/highcharts'
		highchartsExports: 'libs/highcharts/exporting',
		async: 'libs/async/async'
	shim:
		jquery:
			exports: 'jQuery'
		underscore:
			exports: '_'
		backbone:
			deps: ["underscore", "jquery"]
			exports: "Backbone"
		"backbone.marionette":
			deps: ['jquery', 'underscore', 'backbone']
			exports: 'Marionette'
		bootstrap:
			deps: ['jquery']
		hyphenate:
			exports: 'Hyphenate'
		datepicker:
			deps: ['jquery', 'bootstrap']
			exports: "$.fn.datepicker"
		daterangepicker:
			deps: ['jquery', 'bootstrap', 'moment']
			exports: "$.fn.daterangepicker"
		cola:
			deps: ['d3']
			exports: 'cola'
		highcharts:
			deps: ['jquery']
			exports: 'Highcharts'
		highchartsExports:
			deps: ['jquery', 'highcharts']
			exports: 'Highcharts'
		async:
			exports: 'async',
		'jquery-shake':
			deps: ['jquery']
			exports: '$.fn.shake'
	hbs:
		templateExtension: 'handlebars'
		disableI18n: true,
		helpers: true,
		helperPathCallback: (name) -> 'templates/helpers/' + name

require ["app", 'jquery', 'bootstrap'], (App, $) ->
	$(document).ready () ->
		window.NotD = App;
		NotD.start({regionNetwork: '#network', regionSource: '#sources', regionDate: '#region-date', regionTrend: '#region-trend', regionFilter: '#region-filter'});