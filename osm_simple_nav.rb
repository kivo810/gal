require_relative 'lib/graph_loader'
require_relative 'process_logger'
require 'ruby-graphviz'

require 'geocoder'

# Class representing simple navigation based on OpenStreetMap project
class OSMSimpleNav

	# Creates an instance of navigation. No input file is specified in this moment.
	def initialize
		# register
		@load_cmds_list = ['--load', '--load-undir', '--load-dir', '--load-dir-comp', '--load-undir-comp']
		@actions_list = ['--export', '--show-nodes', '--center', '--midist-len', '--midist-time']

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

	def biggest_comp(directed)
		graph_loader = GraphLoader.new(@map_file, @highway_attributes)
		@graph, @visual_graph = graph_loader.biggest_comp(directed)
	end

	#UC04
	def print_all_vertices
		@visual_graph.visual_vertices.each do |index, value|
			puts "Bod s id:(#{index}) LAT: #{value.lat}, LON: #{value.lon}"
		end
	end

	#UC05
	def emphasize_special_vertices_id (id1, id2)
		p @graph
		vertex1_lat = 0
		vertex1_lon = 0
		vertex2_lat = 0
		vertex2_lon = 0
		@visual_graph.visual_vertices.each do |index, value|
			if id1.to_s == index
				vertex1_lat = value.lat.to_f
				vertex1_lon = value.lon.to_f
			elsif id2.to_s == index
				vertex2_lat = value.lat.to_f
				vertex2_lon = value.lon.to_f
			end
		end
		if vertex2_lat > vertex1_lat
			a = vertex1_lat
			vertex1_lat = vertex2_lat
			vertex2_lat = a
		end
		if vertex2_lon > vertex1_lon
			a = vertex1_lon
			vertex1_lon = vertex2_lon
			vertex2_lon = a
		end
		@visual_graph.visual_vertices.each do |index, value|
			if (value.lat.to_f).between?(vertex2_lat, vertex1_lat) && (value.lon.to_f).between?(vertex2_lon,vertex1_lon)

			end
		end
	end

	#UC05
	def emphasize_special_ (geo_start_lat, geo_start_lon, geo_end_lat, geo_end_lon)
		@visual_graph.visual_vertices.each do |index, value|
			if (value.lat.to_f).between?(geo_start_lat, geo_end_lat) && (value.lon.to_f).between?(geo_start_lon,geo_end_lon)

			end
		end
	end

	# Load graph from Graphviz file. This methods loads graph and create +Graph+ as well as +VisualGraph+ instances.
	def import_graph
		graph_loader = GraphLoader.new(@map_file, @highway_attributes)
		@graph, @visual_graph = graph_loader.load_graph_viz
	end

	# Run navigation according to arguments from command line
	def run
		prepare_log
	    process_args

	    # load graph - action depends on last suffix
	    @highway_attributes = ['residential', 'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'unclassified']
	    if file_type(@map_file) == "osm" or file_type(@map_file) == "xml" then
				case @load_cmd
				when '--load-undir'
					load_graph(false)
				when '--load-dir'
					load_graph(true)
				when '--load-undir-comp'
					biggest_comp(false)
				when '--load-dir-comp'
					biggest_comp(true)
				else
					usage
					exit 1
				end
	    elsif file_type(@map_file) == "dot" or file_type(@map_file) == "gv" then
	    	import_graph
	    else
	    	puts "Imput file type not recognized!"
	    	usage
			end

		# perform the operation
	    case @operation
			when '--export'
				@visual_graph.export_graphviz(@out_file)
				return
			when '--show-nodes'
				print_all_vertices
				return
			else
				usage
				exit 1
			end
		@visual_graph.export_graphviz(@out_file)
	end	
end

osm_simple_nav = OSMSimpleNav.new
osm_simple_nav.run
