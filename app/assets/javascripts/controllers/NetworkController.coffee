define ['jquery', 'underscore', 'backbone.marionette', 'json2', 'collections/LinksCollection', 'collections/NodesCollection', 'views/network/NetworkView'], ($, _, Marionette, JSON, LinksCollection, NodesCollection, NetworkView) ->
	Marionette.Controller.extend
		initialize: (options) ->
			this.nodesCollection = new NodesCollection()
			this.linksCollection = new LinksCollection null,
				nodesCollection: this.nodesCollection
			
			this.network = new NetworkView {
				collection: this.linksCollection
			}
			
			NotD.networkRegion.show this.network
			
			NotD.vent.on 'dateChanged', (date) =>
				this.network.showLoading()
				this.linksCollection.setDate date

			NotD.vent.on 'tagAdded', (tag) =>
				this.linksCollection.tags().addAndSelectPrimary tag
				
			NotD.vent.on 'tagsUpdated', (tags) =>
				this.linksCollection.tags().addMultipleAndSelectPrimary tags
				
			NotD.vent.on 'tagRemoved', (tag) =>
				model = this.linksCollection.tags().get( tag.id )
				if model?
					model.set 'deleted', true
					
			NotD.vent.on 'clusterOpen', (clusterId) =>
				this.network.openCluster clusterId
			
			NotD.vent.on 'clusterClose', (clusterId) =>
				this.network.closeCluster clusterId
				
			NotD.vent.on 'showNode', (nodeId, center) =>
				node = this.linksCollection.nodes().get(nodeId)
				if node?
					if center
						#center the node when the expand animation has finished
						this.network.once 'resumed', () -> 
							this.centerNode nodeId
					
					if not this.network.openCluster node.get 'group'
						#if the cluster is already opened, no resume event will be triggered -> center the node
						if center
							this.network.centerNode nodeId
						
					###
					if center
						window.setTimeout () =>
							this.network.centerNode nodeId
						, 1000
					###