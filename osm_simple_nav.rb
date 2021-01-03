require_relative 'lib/graph_loader'
require_relative 'process_logger'
require 'ruby-graphviz'

require 'geocoder'

# Class representing simple navigation based on OpenStreetMap project
class OSMSimpleNav

	# Creates an instance of navigation. No input file is specified in this moment.
	def initialize
		# register
		@load_cmds_list = ['--load']
		@actions_list = ['--export']

		@usage_text = <<-END.gsub(/^ {6}/, '')
	  	Usage:\truby osm_simple_nav.rb <load_command> <input.IN> <action_command> <output.OUT> 
	  	\tLoad commands: 
	  	\t\t --load ... load map from file <input.IN>, IN can be ['DOT']
	  	\tAction commands: 
	  	\t\t --export ... export graph into file <output.OUT>, OUT can be ['PDF','PNG','DOT']
		END
	end

	# Prints text specifying its usage
	def usage
		puts @usage_text
	end

	# Command line handling
	def process_args
		# not enough parameters - at least load command, input file and action command must be given
		unless ARGV.length >= 3
		  puts "Not enough parameters!"
		  puts usage
		  exit 1
		end

		# read load command, input file and action command 
		@load_cmd = ARGV.shift
		unless @load_cmds_list.include?(@load_cmd)
		  puts "Load command not registred!"
		  puts usage
		  exit 1			
		end
		@map_file = ARGV.shift
		unless File.file?(@map_file)
		  puts "File #{@map_file} does not exist!"
		  puts usage
		  exit 1						
		end
		@operation = ARGV.shift
		unless @actions_list.include?(@operation)
		  puts "Action command not registred!"
		  puts usage
		  exit 1			
		end

		# possibly load other parameters of the action
		if @operation == '--export'
		end

		# load output file
		@out_file = ARGV.shift
	end

	# Determine type of file given by +file_name+ as suffix.
	#
	# @return [String]
	def file_type(file_name)
		return file_name[file_name.rindex(".")+1,file_name.size]
	end

	# Specify log name to be used to log processing information.
	def prepare_log
		ProcessLogger.construct('log/logfile.log')
	end

	# Load graph from OSM file. This methods loads graph and create +Graph+ as well as +VisualGraph+ instances.
	def load_graph(directed)
		graph_loader = GraphLoader.new(@map_file, @highway_attributes)
		@graph, @visual_graph = graph_loader.load_graph(directed)
	end

	# Load graph from Graphviz file. This methods loads graph and create +Graph+ as well as +VisualGraph+ instances.
	def import_graph
		graph_loader = GraphLoader.new(@map_file, @highway_attributes)
		@graph, @visual_graph = graph_loader.load_graph_viz
	end

	# Run navigation according to arguments from command line
	def run
		# prepare log and read command line arguments
		# @highway_attributes = %w[residential motorway trunk primary secondary tertiary unclassified]
		# doc = Nokogiri::XML(File.open("data/near_ucl.osm"))
		# g = GraphViz.new(:G, :type => :graph)
		# #p doc
		# xx = 0
		# # doc.root.xpath("node").each do |node|
		# # 	g.add_nodes(node.attr("id"))
		# # 	#puts node.attr("id")
		# # end
		# # doc.root.xpath("way").each do |way|
		# # 	#p way
		# # 	way.xpath("tag").each do |tag|
		# # 		if tag.attr("k") == "highway" && tag.attr("v") == "residential"
		# # 			p tag
		# # 		end
		# # 	end
		# # 	i = 1
		# # 	way.xpath("nd").each do |nn|
		# # 		puts "node #{i}"
		# # 		p nn.attr("ref")
		# # 		i = i + 1
		# # 	end
		# # end
		# # doc.root.xpath("way/nd").each do |nd|
		# # 	#p nd.attr("ref")
		# # end
		# # TODO
		# doc.root.xpath("way").each do |way|
		# 	array = []
		# 	way.xpath("tag").each do |tag|
		# 		if tag.attr("k") == "highway" && tag.attr("v") == "residential"
		# 		#if tag.attr("k") == "highway" && @highway_attributes.include?(tag.attr("v"))
		# 			way.xpath("nd").each do |nd|
		# 				array << nd.attr("ref")
		# 			end
		# 		end
		# 	end
		# 	array.combination(2) { |c|
		# 		if g.get_node(c[0]) == nil
		# 			a = g.add_nodes(c[0])
		# 			#e = g.add_nodes(Vertex.new(c[0]))
		# 		else
		# 			a = g.get_node(c[0])
		# 			#e = g.get_node(c[0])
		# 		end
		# 		if g.get_node(c[1]) == nil
		# 			b = g.add_nodes(c[1])
		# 			#d = g.add_nodes(Vertex.new(c[1]))
		# 		else
		# 			b = g.get_node(c[1])
		# 			#d = g.get_node(c[1])
		# 		end
		# 		#r = Edge.new(a,b, 50, "none")
		# 		# g.add_edge(a,b, :dir => "none")
		# 		# g.add_edges(a, b, :dir => "none")
		# 		#g.add_edge(a,b)
		# 		if xx % 2 == 0
		# 			g.add_edges(a,b, :color => "red")
		# 			xx = xx + 1
		# 		else
		# 			g.add_edges(a,b)
		# 			xx = xx + 1
		# 		end
		#
		# 	}
		# end
		#
		# t = GraphViz::Theory.new( g )
		#
		# pp = OsmHelper.load_graph_attributes(doc, @highway_attributes, false)
		#
		# #p g.node_count
		# puts "node"
		# #p g.get_node_at_index(1)
		# #p g.get_node("1131753366")
		# dist = Geocoder::Calculations.distance_between([50.0894509, 14.4588129], [50.0893950, 14.4589538], :units => :km)
		# p dist
		#
		# p t.range
		#
		#
		# #g.add_edges(g.get_node_at_index(0), g.get_node_at_index(1), :dir => "none")
		# #p g.get_edge_at_index(9)

		#g.output( :png => "graph.png")
		
		prepare_log
	    process_args

	    # load graph - action depends on last suffix
	    @highway_attributes = ['residential', 'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'unclassified']
	    if file_type(@map_file) == "osm" or file_type(@map_file) == "xml" then
	    	puts "OSM not supported!"
	    	usage
				load_graph(false)
				#exit 1
	    elsif file_type(@map_file) == "dot" or file_type(@map_file) == "gv" then
	    	import_graph
	    else
	    	puts "Imput file type not recognized!"
	    	usage
			end

		# perform the operation
	    case @operation
			when '--export'
				puts "im here"
				@visual_graph.export_graphviz(@out_file)
				return
			else
				usage
				exit 1
	    end	
	end	
end

osm_simple_nav = OSMSimpleNav.new
osm_simple_nav.run
