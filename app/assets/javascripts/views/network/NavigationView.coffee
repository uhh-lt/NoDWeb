define ['backbone.marionette', 'underscore', 'hbs!templates/network/navigation'], (marionette, _, tpl) ->
	Marionette.ItemView.extend
		tagName: 'div'
		className: ''
		template :
			type : 'handlebars'
			template : tpl
		width: 80
		segmentToDirection: ['e', 's', 'w', 'n']
		
		events: 
			'mousemove canvas': 'handleMousemove'
			'mouseout canvas': 'handleMouseout'
			'mousedown canvas': 'handleMousedown'
			'mouseup canvas': 'handleMouseup'
			'mousedown button.zoom': 'handleZoomStart'
			'mouseup button.zoom': 'handleZoomStop'
			'mouseout button.zoom': 'handleZoomStop'
		
		onRender: () ->
			this.canvas = this.$el.find('canvas#pan').map( () -> return this )[0]
			this.canvas.width = this.width
			this.canvas.height = this.width
			this.ctx = this.canvas.getContext('2d')
		
			this.drawCanvas()
				
		drawCanvas: (highlight) ->
			w = this.width
			border = 1
			offset = Math.PI / 4
			seg = 0
			oRadius = w / 2 - border / 2
			iRadius = w / 5 - border / 2
			
			this.ctx.clearRect(0, 0, w, w)			
			
			#outter border
			for seg in [0..3]
				this.ctx.beginPath()
				this.ctx.arc(w / 2, w / 2, oRadius, Math.PI / 2 * seg - offset, Math.PI / 2 * (seg + 1) - offset, false)
				this.ctx.lineTo(Math.cos(Math.PI / 2 * (seg + 1) - offset) * iRadius + w / 2, Math.sin(Math.PI / 2 * (seg + 1) - offset) * iRadius + w/2)
				this.ctx.arc(w / 2, w / 2, iRadius, Math.PI / 2 * (seg + 1) - offset, Math.PI / 2 * seg - offset, true)
				this.ctx.lineTo(Math.cos(Math.PI / 2 * seg - offset) * oRadius + w / 2, Math.sin(Math.PI / 2 * seg - offset) * oRadius + w/2)
				
				this.ctx.strokeStyle = '#CCCCCC'
				if highlight? and seg == highlight
					this.ctx.fillStyle = '#EEEEEE'
				else
					this.ctx.fillStyle = '#FFFFFF'
				this.ctx.fill()
				this.ctx.lineWidth = border
				this.ctx.stroke()
				
				this.ctx.beginPath()
				
				this.ctx.moveTo(this.width / 2 + Math.cos(Math.PI / 2 * seg - 0.3) * w / 3.5, this.width / 2 + Math.sin(Math.PI / 2 * seg - 0.3) * w / 3.5)			
				this.ctx.lineTo(this.width / 2 + Math.cos(Math.PI / 2 * seg) * w / 2.5, this.width / 2 + Math.sin(Math.PI / 2 * seg) * w / 2.5)
				this.ctx.lineTo(this.width / 2 + Math.cos(Math.PI / 2 * seg + 0.3) * w / 3.5, this.width / 2 + Math.sin(Math.PI / 2 * seg + 0.3) * w / 3.5)
				this.ctx.lineTo(this.width / 2 + Math.cos(Math.PI / 2 * seg - 0.3) * w / 3.5, this.width / 2 + Math.sin(Math.PI / 2 * seg - 0.3) * w / 3.5)
				
				this.ctx.fillStyle = '#000000'
				this.ctx.fill()
				this.ctx.stroke()
				
			
		
		getSegmentByMouseposition: (pos) ->
			x = pos.x - this.width / 2
			y = pos.y - this.width / 2
			
			if Math.sqrt(Math.pow(x) + Math.pow(y)) < this.width / 5
				4
			else
				offset = Math.PI / 4
				alpha = (Math.atan(y / x) + Math.PI / 2 - Math.PI / 4)
				
				if x < 0
					alpha += Math.PI
				
				alpha = (alpha + Math.PI * 2) % (Math.PI * 2)
				
				ret = 0
				
				for seg in [0..3]
					b1 = (Math.PI / 2 * seg) % (Math.PI * 2)
					b2 = (Math.PI / 2 * (seg + 0.9999999)) % (Math.PI * 2)
				
					if Math.min(b1, b2) <= alpha and Math.max(b1, b2) > alpha
						ret = seg
						break;
				ret
		
		handleMousemove: (e) ->
			mousePosition = {x: e.clientX - this.$el.offset().left, y: e.clientY - this.$el.offset().top}
			this.drawCanvas( this.getSegmentByMouseposition(mousePosition) )
			
		handleMouseout: (e) ->
			this.drawCanvas()
			this.handleMouseup()
			
		handleMousedown: (e) ->
			this.moveInterval = window.setInterval () =>
				mousePosition = {x: e.clientX - this.$el.offset().left, y: e.clientY - this.$el.offset().top}
				this.trigger('pan', this.segmentToDirection[this.getSegmentByMouseposition(mousePosition)])
			, 50
			
		handleMouseup: (e) ->
			if this.moveInterval?
				window.clearInterval this.moveInterval
				
		handleZoomStart: (e) ->
			console.log(e.currentTarget)
		
			if $(e.currentTarget).hasClass('in')
				this.zoomInterval = window.setInterval () =>
					this.trigger('zoom', 1)
				, 50
			else
				this.zoomInterval = window.setInterval () =>
					this.trigger('zoom', -1)
				, 50
			
		handleZoomStop: (e) ->
			if this.zoomInterval?
				window.clearInterval this.zoomInterval