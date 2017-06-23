define(['backbone.marionette', 'json2', 'd3', 'jquery', 'underscore', 'async', 'cola'], function(marionette, JSON, d3, $, _, async, cola) { 
	return Marionette.ItemView.extend({	
		tagName: 'div',
		className: '',
		template : false,
		
		events : {
			'mouseover .linkhandle' : 'linkOver',
			'mouseout .linkhandle' : 'linkOut',
			'click .linkhandle' : 'linkClick',
			'mouseover .node': 'nodeOver',
			'mouseout .node': 'nodeOut'
		},
		
		linksByNode: {},
		tags: [],
		
		setUrl: function(url){
			this.url = url;
		},
		
		render: function(){
			if(!_.isUndefined(this.currentDataShown) && this.url == this.currentDataShown)return false;
			this.currentDataShown = this.url;
			
			var self = this;
			
			var w = window,
				d = document,
				e = d.documentElement,
				g = d.getElementsByTagName('body')[0],
				documentWidth = this.$el.width() || 100; //w.innerWidth || e.clientWidth || g.clientWidth,
				documentHeight = this.$el.height() || 100; //w.innerHeight || e.clientHeight || g.clientHeight
				;
					
			var border = 100,	//space for labels
				width = documentWidth - 2*border, // svg width
				height = documentHeight - 2*border,	// svg height
				borderMargin = 10, //margin of labels
				dr = 4,			// default point radius
				off = 15,		// cluster hull offset
				expand = {}, // expanded clusters
				nodeMap = d3.map(),
				linkMap = d3.map(),
				fontSize = 10,
				blacklist =	{},
				topNodesByGroup = {},
				freezeHull = {},
				data, net, force, hullg, hull, linkg, link, linkhandle, nodeg, node, texts, vis, container, borderRect;
				;
			
			var curve = d3.svg.line()
					.interpolate("cardinal-closed")
					.tension(.85);
			 
			var fill = d3.scale.category20();

			function resize(el){
				w = window,
					d = document,
					e = d.documentElement,
					g = d.getElementsByTagName('body')[0],
					documentWidth = el.width() || w.innerWidth || e.clientWidth || g.clientWidth,
					documentHeight = el.height() || w.innerHeight || e.clientHeight || g.clientHeight
					;
					
				border = 100,	//space for labels
					width = documentWidth - 2*border, // svg width
					height = documentHeight - 2*border	// svg height
					;
			}
			
			/*
			Tick callback
			*/
				function tick(e) {
					var hulls = [];
					
					if (!hull.empty()) {
						hulls = convexHulls(net.nodes, getGroup, off);
						
						hull.data(hulls)
								.attr("d", drawCluster);
					}
								
								
					//console.log(e.alpha);	
					//Restrict to rectangle		
					node
						.attr("transform", function(d) {
							/*if(d.size){
								if(d.x < d.size)
									d.x = d.size;
								else if(d.x > width + border)
									d.x = width + border;
								
								if(d.y < d.size)
									d.y = d.size;
								else if(d.y > height + 2 * border - d.size)
									d.y = height + 2 * border - d.size;
							}else{*/
								if(d.x < border)
									d.x = border;
								else if(d.x > width + border)
									d.x = width + border;
								
								if(d.y < border)
									d.y = border;
								else if(d.y > height + border)
									d.y = height + border;
							//}
							
							return 'translate(' + d.x + ',' + d.y + ')'; 
						});
				
					link.attr('d', function(d){
								var sx = d.source.x;
								var sy = d.source.y;
								var tx = d.target.x;
								var ty = d.target.y;
								
								var x1 = d.target.x;
								var y1 = d.source.y;

								if(d.target.x != d.source.x && d.target.y != d.source.y){							
									if(sx > tx){
										var ox = sx;
										var oy = sy;
										sx = tx; sy = ty; tx = ox; ty = oy;
									}
									
									var cx1 = sx + (tx - sx) * 0.8;
									var cy1 = sy;
									var cx2 = tx;
									var cy2 = sy + (ty - sy) * 0.8;
									return ['M', sx, sy, 'C', cx1, cy1, cx2, cy2, tx, ty].join(' ');
								}
									
								if(d.source.y == d.target.y){
									var sign = -1;
									if(d.source.y < height / 2)
										sign = 1;
										
									x1 = sx;
									x2 = tx;
									
									y1 = y2 = sy + 0.2 * sign * Math.abs(sx - tx);
									
									return ['M', sx, sy, 'C', x1, y1, x2, y2, tx, ty].join(' ');
								}
								
								if(d.source.x == d.target.x){
									var sign = -1;
									if(d.source.x < width / 2)
										sign = 1;
										
									y1 = sy;
									y2 = ty;
									
									x1 = x2 = sx + 0.2 * sign * Math.abs(sy - ty);
									
									return ['M', sx, sy, 'C', x1, y1, x2, y2, tx, ty].join(' ');
								}
							});
							
					linkhandle.attr('d', function(d){
								var sx = d.source.x;
								var sy = d.source.y;
								var tx = d.target.x;
								var ty = d.target.y;
								
								var x1 = d.target.x;
								var y1 = d.source.y;

								if(d.target.x != d.source.x && d.target.y != d.source.y){
									if(sx > tx){
										var ox = sx;
										var oy = sy;
										sx = tx; sy = ty; tx = ox; ty = oy;
									}
									
									var cx1 = sx + (tx - sx) * 0.8;
									var cy1 = sy;
									var cx2 = tx;
									var cy2 = sy + (ty - sy) * 0.8;
									return ['M', sx, sy, 'C', cx1, cy1, cx2, cy2, tx, ty].join(' ');
								}
									
								if(d.source.y == d.target.y){
									var sign = -1;
									if(d.source.y < height / 2)
										sign = 1;
										
									x1 = sx;
									x2 = tx;
									
									y1 = y2 = sy + 0.2 * sign * Math.abs(sx - tx);
									
									return ['M', sx, sy, 'C', x1, y1, x2, y2, tx, ty].join(' ');
								}
								
								if(d.source.x == d.target.x){
									var sign = -1;
									if(d.source.x < width / 2)
										sign = 1;
										
									y1 = sx;
									y2 = tx;
									
									x1 = x2 = sx + 0.2 * sign * Math.abs(sy - ty);
									
									return ['M', sx, sy, 'C', x1, y1, x2, y2, tx, ty].join(' ');
								}
							});
					
					texts.attr("transform", function(d) {
						if(d.x == border){
							return "translate(" + (border - borderMargin) + "," + d.y + ")";	
						}
						if(d.x == width + border){
							return "translate(" + (d.x + borderMargin) + "," + d.y + ")";	
						}
						if(d.y == border){
							return "translate(" + d.x + "," + (border - borderMargin) + ")rotate(90)";	
						}
						if(d.y == height + border){
							return "translate(" + d.x + "," + (height + border + borderMargin) + ")rotate(90)";	
						}
						return "translate(" + (d.x + 7) + "," + (d.y + 2) + ")";
					}).attr("width", function(d) {
						if(d.x == border){
							return border;	
						}
						if(d.x == width + border){
							return border;	
						}
						return null;
					}).attr("height", function(d) {
						if(d.y == border){
							return border;	
						}
						if(d.y == height + border){
							return border;	
						}
						return null
					}).style("text-anchor", function(d) {
						if(d.x == border){
							return 'end';
						}
						if(d.x == width + border){
							return 'start';	
						}
						if(d.y == border){
							return 'end';
						}
						if(d.y == height + border){
							return 'start';	
						}
						return 'start';
					})
					;
				}
			
			/*
			Zoom behavior
			*/
			var zoomBehavior = d3.behavior.zoom()
				.scaleExtent([1, 5])
				.on('zoom', zoomed);
			
			/*
			Drag behaviors and callbacks
			*/
				function nodeDragstarted(d, i){
					d.dragstart = {
						x: d.x,
						y: d.y
					};
					
					d3.event.sourceEvent.stopPropagation();
					force.stop();
				}
				
				function nodeDragMove(d, i){
					d.px += d3.event.dx;
					d.py += d3.event.dy;
					d.x += d3.event.dx;
					d.y += d3.event.dy;
					tick();
					
					var group = d.group;
				}
				
				function nodeDragend(d, i){
					var group = d.group;
				
					if(!_.isUndefined(d.dragstart)){
						if(Math.abs(d.dragstart.x - d.x) + Math.abs(d.dragstart.y - d.y) > 5){						
							if(_.isUndefined(freezeHull[group]) || _.isNull(freezeHull[group])){
								freezeHull[group] = window.setTimeout(_.bind(function(){
									freezeHull[this] = null;
								}, group), 300);
								
								d.fixed = true;
								if(!_.isUndefined(d.nodes) && d.nodes.length > 0){
									d.nodes[0].fixed = true;
								}
							}else{
								window.clearTimeout(freezeHull[group]);
								freezeHull[group] = window.setTimeout(_.bind(function(){
									freezeHull[this] = null;
								}, group), 300);
							}
						}
					}
			
					tick();
					force.resume();
					self.resetHover();
				}
				
				var nodeDragBehavior = d3.behavior.drag()
					.origin(function(d){ return d; })
					.on('dragstart', nodeDragstarted)
					.on('drag', nodeDragMove)
					.on('dragend', nodeDragend)
					;
					
				function hullDragstarted(d, i){
					d.dragmoves = 0;		
					//d3.event.sourceEvent.stopPropagation();
					force.stop();
				}
				
				function hullDragMove(d, i){
					//Move all nodes in the hull
					var group = d.group;
				
					if(!_.isUndefined(d.dragmoves))
						d.dragmoves++;
				
					node.each(function(nd, ni){
						if(nd.group == group){
							nd.px += d3.event.dx;
							nd.py += d3.event.dy;
							nd.x += d3.event.dx;
							nd.y += d3.event.dy;
						}
					});
					tick();
				}
				
				function hullDragend(d, i){
					//d3.event.sourceEvent.stopPropagation();
					var group = d.group;
				
					if(!_.isUndefined(d.dragmoves) && d.dragmoves > 1){					
						if(_.isUndefined(freezeHull[group]) || _.isNull(freezeHull[group])){
							freezeHull[group] = window.setTimeout(_.bind(function(){
								freezeHull[this] = null;
							}, group), 300);
						}else{
							window.clearTimeout(freezeHull[group]);
							freezeHull[group] = window.setTimeout(_.bind(function(){
								freezeHull[this] = null;
							}, group), 300);
						}
					}
				
					var nodesDistance = [];
					/*
					Use geom. distance
					*/
						/*
						var center = d3.geom.polygon(d.path).centroid();	
						node.each(function(nd, ni){
							if(nd.group == group){
								var dist = Math.sqrt(Math.pow(nd.x - center[0], 2) + Math.pow(nd.y - center[1], 2));
							
								nodesDistance.push({node: nd, distance: dist});
							}
						});
						*/
					/*
					LinkCount distance
					*/
					node.each(function(nd, ni){
						if(nd.group == group){
							if(typeof self.linksByNode[nd.elementId] != 'undefined'){
							var dist = self.linksByNode[nd.elementId].length * -1;
						
							nodesDistance.push({node: nd, distance: dist});
							}
						}
					});
					
					nodesDistance.sort(function(a, b){
						return a.distance - b.distance;
					});
										
					//Fix 3 nodes in the center of the cluster
					for(var i = 0;i < Math.min(3, nodesDistance.length); i++){
						nodesDistance[i].node.fixed = true;
					}
				
					tick();
					force.resume();
					self.resetHover();
				}
				
				var hullDragBehavior = d3.behavior.drag()
					.origin(function(d){ return d; })
					.on('dragstart', hullDragstarted)
					.on('drag', hullDragMove)
					.on('dragend', hullDragend)
					;
			
			function getTopLabels(group){
				if(typeof topNodesByGroup[group] == 'undefined')
					return [];
				
				var ret = [];
				
				for(var i = 0;i < Math.min(topNodesByGroup[group].length, 3); i++){
					var nodeId = topNodesByGroup[group][i];
					ret.push(nodeMap.get(nodeId).name);
				}
				
				return ret;
			}
			
			function noop() { return false; }
			 
			function nodeid(n) {
				return n.size ? "_g_"+n.group : n.name;
			}
			 
			function linkid(l) {
				var u = nodeid(l.source),
						v = nodeid(l.target);
				return u<v ? u+"|"+v : v+"|"+u;
			}
			 
			function getGroup(n) { return n.group; }
			 
			// constructs the network to visualize
			function network(data, prev, index, expand) {
				expand = expand || {};
				var gm = {},		// group map
						nm = {},		// node map
						lm = {},		// link map
						gn = {},		// previous group nodes
						gc = {},		// previous group centroids
						nodes = [], // output nodes
						links = []; // output links
			 
				// process previous nodes for reuse or centroid calculation
				if (prev) {
					prev.nodes.forEach(function(n) {
						var i = index(n), o;
						if (n.size > 0) {
							gn[i] = n;
							n.size = 0;
						} else {
							o = gc[i] || (gc[i] = {x:0,y:0,count:0});
							o.x += n.x;
							o.y += n.y;
							o.count += 1;
						}
					});
				}
			 
				// determine nodes
				for (var k=0; k<data.nodes.length; ++k) {
					var n = data.nodes[k],
							i = index(n),
							l = gm[i] || (gm[i]=gn[i]) || (gm[i]={group:i, size:0, nodes:[]});
			 
					if (expand[i]) {
						// the node should be directly visible
						nm[n.name] = nodes.length;
						nodes.push(n);
						if (gn[i]) {
							// place new nodes at cluster location (plus jitter)
							n.x = gn[i].x + Math.random();
							n.y = gn[i].y + Math.random();
						}
					} else {
						// the node is part of a collapsed cluster
						if (l.size == 0) {
							// if new cluster, add to set and position at centroid of leaf nodes
							nm[i] = nodes.length;
							nodes.push(l);
							if (gc[i]) {
								l.x = width / 2 + Math.random() * 300; //gc[i].x / gc[i].count;
								l.y = height / 2; //gc[i].y / gc[i].count;
							}
						}
						l.nodes.push(n);
					}
				// always count group size as we also use it to tweak the force graph strengths/distances
					l.size += 1;
					n.group_data = l;
				}
			 
				for (i in gm) { gm[i].link_count = 0; }
			 
				// determine links
				for (k=0; k<data.links.length; ++k) {
					var e = data.links[k],
							u = index(e.source),
							v = index(e.target);
			
					if (u != v) {
						gm[u].link_count++;
						gm[v].link_count++;
					}
					u = expand[u] ? nm[e.source.name] : nm[u];
					v = expand[v] ? nm[e.target.name] : nm[v];
					var i = (u<v ? u+"|"+v : v+"|"+u),
							l = lm[i] || (lm[i] = {source:u, target:v, size:0, id: e.id});
			
					l.size += 1;
				}
				for (i in lm) { 
					if(lm[i].source == lm[i].target)continue;
					links.push(lm[i]);
				}
			 
				return {nodes: nodes, links: links};
			}
			 
			function convexHulls(nodes, index, offset) {
				var hulls = {};
			 
				// create point sets
				for (var k=0; k<nodes.length; ++k) {
					var n = nodes[k];
					if (n.size) continue;
					var i = index(n),
							l = hulls[i] || (hulls[i] = []);
					l.push([n.x-offset, n.y-offset]);
					l.push([n.x-offset, n.y+offset]);
					l.push([n.x+offset, n.y-offset]);
					l.push([n.x+offset, n.y+offset]);
				}
			 
				// create convex hulls
				var hullset = [];
				for (i in hulls) {
					hullset.push({group: i, path: d3.geom.hull(hulls[i])});
				}
			 
				return hullset;
			}
			 
			function drawCluster(d) {
				return curve(d.path); // 0.8
			}
			
			function preprocess(data) {
				var gm = {},
				blacklist = {},
				nodes = [],
				links = []
			
				// D3 uses the the object indices in array instead of their actual ids;
				// create maps of nodes and links by id
				data.nodes.forEach(function(n) {
					nodeMap.set(n.id, n)
				});
				// Replace source and target attributes (represented by ids) by the actual objects.
				data.links.forEach(function(l) {
					l.source = nodeMap.get(l.source);
					l.target = nodeMap.get(l.target);
				});
				
				data.nodes.forEach(function(n) {
					l = gm[n.group] || (gm[n.group]={nodes:[]}); 
					l.nodes.push(n)
				});
			
				for (i in gm) {
					gm[i].nodes.forEach(function(n) {
						if(n.zoom != 0)
							blacklist[n.id] = true
						else
							nodes.push(n)
					});
				}
				data.nodes = nodes;
			
				data.links.forEach(function(e) {
						if(!(blacklist[e.source.id] || blacklist[e.target.id])) links.push(e)
				});
				data.links = links;
				
				//Find most important nodes for each cluster
				data.groups.forEach(function(group){
					for(var groupId in group){
						topNodesByGroup[groupId] = group[groupId];
					}
				});
			}
				 
			function init() {
				//if (force) force.stop();
				
				net = network(data, net, getGroup, expand);
				
				/*force = d3.layout.force()
						.nodes(net.nodes)
						.links(net.links)
						.size([width, height])
						.linkDistance(function(l, i) {
								var n1 = l.source, n2 = l.target;
							// larger distance for bigger groups:
							// both between single nodes and _other_ groups (where size of own node group still counts),
							// and between two group nodes.
							//
							// reduce distance for groups with very few outer links,
							// again both in expanded and grouped form, i.e. between individual nodes of a group and
							// nodes of another group or other group node or between two group nodes.
							//
							// The latter was done to keep the single-link groups ('blue', rose, ...) close.
							return 30 +
								Math.min(20 * Math.min((n1.size || (n1.group != n2.group ? n1.group_data.size : 0)),
																			 (n2.size || (n1.group != n2.group ? n2.group_data.size : 0))),
										 -30 +
										 30 * Math.min((n1.link_count || (n1.group != n2.group ? n1.group_data.link_count : 0)),
																	 (n2.link_count || (n1.group != n2.group ? n2.group_data.link_count : 0))),
										 100);
					})
					.linkStrength(function(l, i) {
							return 1;
					})
					.gravity(0.2)	 // gravity+charge tweaked to ensure good 'grouped' view (e.g. green group not smack between blue&orange, ...
					.charge(-2000)		// ... charge is important to turn single-linked groups to the outside
					.start();*/
					
				var d3cola = cola.d3adaptor()
					.size([width, height]);
					
				d3cola
					.nodes(net.nodes)
					.links(net.links)
					.size([width, height])
					.jaccardLinkLengths(90)
					/*.linkDistance(function(l, i) {
							var n1 = l.source, n2 = l.target;
						// larger distance for bigger groups:
						// both between single nodes and _other_ groups (where size of own node group still counts),
						// and between two group nodes.
						//
						// reduce distance for groups with very few outer links,
						// again both in expanded and grouped form, i.e. between individual nodes of a group and
						// nodes of another group or other group node or between two group nodes.
						//
						// The latter was done to keep the single-link groups ('blue', rose, ...) close.
						return 30 +
							Math.min(20 * Math.min((n1.size || (n1.group != n2.group ? n1.group_data.size : 0)),
																		 (n2.size || (n1.group != n2.group ? n2.group_data.size : 0))),
									 -30 +
									 30 * Math.min((n1.link_count || (n1.group != n2.group ? n1.group_data.link_count : 0)),
																 (n2.link_count || (n1.group != n2.group ? n2.group_data.link_count : 0))),
									 100);
					})*/
					.avoidOverlaps(true)
					.start(10,15,10)
					;
			 
				hullg.selectAll("path.hull").remove();
				hull = hullg.selectAll("path.hull")
						.data(convexHulls(net.nodes, getGroup, off))
					.enter().append("path")
						.attr("class", "hull")
						.attr("d", drawCluster)
						.style("fill", function(d) { return fill(d.group); })
						.on("click", function(d) {
							if(!_.isUndefined(freezeHull[d.group]) && !_.isNull(freezeHull[d.group]))return;
							
							console.log("hull click", d, arguments, this, expand[d.group]);
							expand[d.group] = false; init();
				 	 	});
				 	 	 
				link = linkg.selectAll("path.link").data(net.links, linkid);
				link.exit().remove();
				link.enter().append("svg:path")
						.attr("id", function(d){
							if(!_.isUndefined(d.id)){
								d.elementId = 'rel-' + d.id;
								return d.elementId;
							}
							var src = d.source.id;
							if(typeof d.source.id == 'undefined')
								src = 'g' + d.source.group;
						
							var tgt = d.target.id;
							if(typeof d.target.id == 'undefined')
								tgt = 'g' + d.target.group;
						
							d.elementId = src + '-' + tgt;
						
							return 'link-' + src + '-' + tgt;
						})
						.attr('pointer-events', 'all')
						.attr("class", "link")
						.attr('d', function(d){
							return 'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y;
						})
						.style("stroke-width", function(d) { return d.size || 1; });
						
				linkhandle = linkg.selectAll("path.linkhandle").data(net.links, linkid);
				linkhandle.exit().remove();
				linkhandle.enter().append("svg:path")
						.attr('data-id', function(d){
							if(!_.isUndefined(d.id)){
								d.elementId = 'rel-' + d.id;
								return d.elementId;
							}
							var src = d.source.id;
							if(typeof d.source.id == 'undefined')
								src = 'g' + d.source.group;
						
							var tgt = d.target.id;
							if(typeof d.target.id == 'undefined')
								tgt = 'g' + d.target.group;
						
							d.elementId = src + '-' + tgt;
							
							return d.elementId;
						})
						.attr("id", function(d){
							return 'linkhandle-' + d.elementId;
						})
						.attr('data-relation-id', function(d){
							//console.log(d._id);
							return d.id;
						})
						.attr("class", "linkhandle")
						.attr('d', function(d){
							return 'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y;
						});
						
				link.each(function(d){
					var src = d.source.id;
					if(typeof d.source.id == 'undefined')
						src = 'g' + d.source.group;
				
					var tgt = d.target.id;
					if(typeof d.target.id == 'undefined')
						tgt = 'g' + d.target.group;
					
					if(typeof self.linksByNode[src] == 'undefined')
						self.linksByNode[src] = [];
					self.linksByNode[src].push(d);
					
					if(typeof self.linksByNode[tgt] == 'undefined')
						self.linksByNode[tgt] = [];
					self.linksByNode[tgt].push(d);
				});
			
				node = nodeg.selectAll("g.node").data(net.nodes, nodeid);
				node.exit().remove();
				node.enter().append("g")
					.attr('data-id', function(d){
						var id = d.id;
						if(typeof d.id == 'undefined')
							id = 'g' + d.group;
					
						d.elementId = id;
					
						return id;
					})
					.attr("id", function(d){					
						return 'node-' + d.elementId;
					})
					// if (d.size) -- d.size > 0 when d is a group node.
					.attr("class", function(d) { return "node" + (d.size?"":" leaf"); })
					.attr("transform", function(d) { return 'translate(' + d.x + ',' + d.y + ')'; })
					.on("click", function(d) {
							if(!_.isUndefined(freezeHull[d.group]) && !_.isNull(freezeHull[d.group]))return;
					
							console.log("node click", d, arguments, this, expand[d.group]);
							expand[d.group] = !expand[d.group];
							init();
					}).append('circle')
						.attr("r", function(d) { return d.size ? d.size + dr : dr * 2; })
						.style("fill", function(d) {
							if(d.size){
								return fill(d.group);
							}else{
								return 'url(#' + d.type + ')';
							}
						})
					;
					/*.append('image')
						.attr("width", function(d) { return d.size ? (d.size + dr) * 2: (dr+1) * 2; })
						.attr("height", function(d) { return d.size ? (d.size + dr) * 2: (dr+1) * 2; })
						.style("fill", function(d) { return fill(d.group); })
					;*/
						/*.on('mouseover', handleNodeOver)
						.on('mouseout', handleNodeOut)
						;*/
							
				node.each(function(d){
							if(d.size){
								var topLabels = d3.select(this).selectAll('text.top-label-stroke').data(getTopLabels(d.group));
								topLabels.exit().remove();
								/*topLabels.enter()
									.append('svg:text')
										.attr("class", function(d, i){ return "top-label-stroke top-label-stroke-" + i})
										.attr("fill", "none")
										.attr("stroke", "#FFFFFF")
										.attr("stroke-width",2)
										.text(function(d){ return d; })
										.attr("y", function(d, i){
											if(i == 0)
												return 0;
											else if(i == 1)
												return -10;
											else if(i == 2)
												return 10;
										})
										.attr("font-size", function(){
												return 12;
										});*/
										
								d3.select(this).selectAll('text.top-label').data(getTopLabels(d.group));
								topLabels.exit().remove();
								topLabels.enter()
									.append('svg:text')
										.attr("class", function(d, i){ return "top-label top-label-" + i})
										.attr("fill", "black")
										.text(function(d){ return d; })
										.attr("y", function(d, i){
											if(i == 0)
												return 0;
											else if(i == 1)
												return -10;
											else if(i == 2)
												return 10;
										})
										.attr("font-size", function(){
											return 12
										});
								
								
							}	
						});
				
				texts = container.selectAll("g.label").data(net.nodes, nodeid)
				texts.exit().remove();
				var newText = texts.enter().append("g")
					.attr('data-id', function(d){
						var id = d.id;
						if(typeof d.id == 'undefined')
							id = 'g' + d.group;
					
						d.elementId = id;
					
						return id;
					})
					.attr("class", "label")
					.attr("id", function(d){					
						return 'label-' + d.elementId;
					});
				
				newText.append('text')
					.attr("fill", "none")
					.attr("stroke", "#FFFFFF")
					.attr("stroke-width", "2")
					.text(function(d) {	return d.name;	});
					
				newText.append('text')
					.attr("fill", "black")
					.text(function(d) {	return d.name;	});
				
			
				texts = container.selectAll("text.label").data(net.nodes, nodeid)
				texts.exit().remove();
				texts.enter().append("text")
					.attr('data-id', function(d){
						var id = d.id;
						if(typeof d.id == 'undefined')
							id = 'g' + d.group;
					
						d.elementId = id;
					
						return id;
					})
					.attr("id", function(d){					
						return 'label-' + d.elementId;
					})
					.attr("class", "label")
					.attr("fill", "black")
					.text(function(d) {	return d.name;	});
			 
				node.call(nodeDragBehavior);
				texts.call(nodeDragBehavior);
				
				hull.call(hullDragBehavior);
			 
				self.resetHover();
				
				self.renderTags();
			 
				//force.on("tick", tick);
				
				
				d3cola.on('tick', tick);
				
				//tick();
			}
			
			function zoomed(){
				container.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
				
				texts.style("font-size", function(d){
					return (fontSize / d3.event.scale) + 'px';
				});
			}
			
			// --------------------------------------------------------
			
			this.$el.html('<span class="loading fa fa-spin fa-spinner fa-5x"></span>');
			
			d3.json(this.url, _.bind(function(json) {
				var body = d3.select(this.el);

				this.$el.empty();
				 			
				resize(this.$el);
				
				vis = body.append('svg');
				vis
					 .attr("width", width + 200)
					 .attr("height", height + 200);
					 
				//vis.call(zoomBehavior);
				
				var defs = vis.append('defs');
				defs.append('pattern')
					.attr('id', 'PERSON')
					.attr('x', -12)
					.attr('y', -12)
					.attr('patternUnits', 'userSpaceOnUse')
					.attr('height', 20)
					.attr('width', 20)
					.append('image')
						.attr('x', 0)
						.attr('y', 0)
						.attr("width", 300)
						.attr("height", 300)
						.attr('transform', 'scale(0.08)')
						.attr('xlink:href', './assets/images/user77.svg')
					;
				defs.append('pattern')
					.attr('id', 'ORGANIZATION')
					.attr('x', -12)
					.attr('y', -12)
					.attr('patternUnits', 'userSpaceOnUse')
					.attr('height', 20)
					.attr('width', 20)
					.append('image')
						.attr('x', 0)
						.attr('y', 0)
						.attr("width", 300)
						.attr("height", 300)
						.attr('transform', 'scale(0.08)')
						.attr('xlink:href', './assets/images/building8.svg')
				
				container = vis.append('g');
				borderRect = container.append('rect')
					.attr('class', 'border')
					.attr('x', border)
					.attr('y', border)
					.attr('width', width)
					.attr('height', height)
				;
				hullg = container.append("g");
				linkg = container.append("g");
				nodeg = container.append("g");
				this.tagsg = container.append("g")
					.attr('class', 'tags');
				
				data = json;
				preprocess(data);
				init();
				
				//Load all Tags
				this.loadTags(data.links);
							 
				container.attr("opacity", 1e-6)
					.transition()
						.duration(1000)
						.attr("opacity", 1);
			}, this));
		},
		
		loadTags: function(links){
			var ids = [];
			for(var i in links)
				ids.push(links[i].id);
		
			if(ids.length == 0)return;
			
			$.getJSON(jsRoutes.controllers.Tags.byRelationships(ids.join(',')).url, _.bind(function(tags){
				for(var i = 0;i < tags.length; i++){
					if(!_.isEmpty(tags[i])){
						for(var key in tags[i])
							this.tags.push(tags[i][key]);
					}
				}
				
				this.renderTags();
			}, this));
		},
		
		renderTags: function(){
			this.tagsg.selectAll('text')
				.remove();
				
				this.tagsg.selectAll('text').data(this.tags)
				.enter()
				.append('text')
				.attr('dy', -3)
				.append('textPath')
					.attr('xlink:href', function(d, i){
						return '#rel-' + d[0].relationship
					})
					.attr('startOffset', '50%')
					.text(function(d){
						return d[0].label;
					});
		},
		
		setTag: function(tag){
			this.tags.push(tag);
			
			this.renderTags();
		},
		
		removeTag: function(rem){
			this.tags = _.filter(this.tags, function(tag){
				if(tag[0].relationship == rem.relation && tag[0].label == rem.label)
					return false;
				return true;
			});
			
			this.renderTags();
		},
		
		linkOver: function(e){
			var linkhandle = $(e.currentTarget);
			var linkId = linkhandle.attr('data-id');
			
			d3.select("#link-" + linkId).classed({hover: true});
			
		},
		
		linkOut: function(e){
			var linkhandle = $(e.currentTarget);
			var linkId = linkhandle.attr('data-id');
			
			d3.select("#link-" + linkId).classed({hover: false});
		},
		
		linkClick: function(e){
			console.log('Link click');
			var node = d3.select(e.currentTarget);
			NotD.vent.trigger('relationSelected', node.attr('data-relation-id'));
		},
		
		nodeOver: function(e){
			this.$el.addClass("hover");
			var node = d3.select(e.currentTarget);
			node.classed({hover: true});

			var elementId = node.attr('data-id');
			d3.select('#label-' + elementId).classed({hover: true});
			
			this.linksByNode[elementId].forEach(function(l){
				d3.select('#' + l.elementId).classed({hover: true});
				if(l.target.elementId != elementId){
					d3.select('#node-' + l.target.elementId).classed({parentHover: true});
					d3.select('#label-' + l.target.elementId).classed({parentHover: true});
				}
				if(l.source.elementId != elementId){
					d3.select('#node-' + l.source.elementId).classed({parentHover: true});
					d3.select('#label-' + l.source.elementId).classed({parentHover: true});
				}
			});
		},
		
		nodeOut: function(e){
			this.$el.removeClass("hover");
			var node = d3.select(e.currentTarget);
			node.classed({hover: false});
			

			var elementId = node.attr('data-id');
			//d3.select('#label-' + elementId).classed({hover: false});
			
			this.linksByNode[elementId].forEach(function(l){
				d3.select('#' + l.elementId).classed({hover: false});
				if(l.target.elementId != elementId){
					d3.select('#node-' + l.target.elementId).classed({parentHover: false});
					d3.select('#label-' + l.target.elementId).classed({parentHover: false});
				}
				if(l.source.elementId != elementId){
					d3.select('#node-' + l.source.elementId).classed({parentHover: false});
					d3.select('#label-' + l.source.elementId).classed({parentHover: false});
				}
			});
		},
		
		resetHover: function(){
			console.log('Reset drag');
			this.$el.removeClass("hover");
			this.$el.find('.hover').removeClass('hover');
			this.$el.find('.parentHover').removeClass('parentHover');
		}
	});
});
