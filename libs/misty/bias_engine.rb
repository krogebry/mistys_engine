
module Misty

  class BiasEngine
    @rules
    @subjects

    @biases

    @descriptions

    def initialize()
      @biases = []
      @descriptions = {}
      load_bias_defs
    end

    def load_bias_defs
      rules = ""
      Dir.glob(File.join(format('%s/bias_defs/*.rb', LIB_DIR))).each do |filename|
        rules << File.read(filename)
      end
      #pp rules
      @rules = rules
    end


    def converge( tokens, entities )
      #@tokens = tokens
      # found_tokens = []
      # found_tokens << find_attributes( 'Trump' )
      # found_tokens << find_conjectives( 'Trump' )
      # found_tokens.flatten.compact
      @biases.each do |bias|
        bias.run( tokens, entities, @descriptions )
        # pp bias

        if bias.found_matches > 0
          Log.debug(format('Article is bias on rule [%s] @%i matches', bias.name, bias.found_matches).yellow)
        end
      end
    end

    def compile()
      self.instance_eval( @rules )
    end

    def bias( name, &block )
      bias = BiasEngineParts::Bias.new( name )
      bias.instance_eval( &block )
      @biases.push( bias )
    end

    def is_described_as( key, &block )
      @descriptions[key] = self.instance_eval( &block )
    end

    def words( a )
      a
    end

  end

  module BiasEngineParts
    class Bias
      @data
      @name
      @subjects
      @descriptions

      @found_matches

      attr_accessor :found_matches, :name
      def initialize( name )
        @data = {}
        @name = name
        @subjects = []
        @found_matches = 0.0
      end

      def find_attributes( tokens, subject )
        ro = []
        return if tokens == nil
        tokens.select{|t| t['lemma'] == subject && t['dependencyEdge']['label'] == 'NSUBJ' }.each do |t|
          hti = t['dependencyEdge']['headTokenIndex']
          ro << tokens.select{|token| 
            token['dependencyEdge']['headTokenIndex'] == hti && token['dependencyEdge']['label'] == 'ATTR'
          }
        end
        ro.flatten
      end

      def find_conjectives( tokens, subject )
        ro = []
        return if tokens == nil
        tokens.select{|t| t['lemma'] == subject && t['dependencyEdge']['label'] == 'NSUBJ' }.each do |t|
          hti = t['dependencyEdge']['headTokenIndex']
          ro << tokens.select{|token| 
            token['dependencyEdge']['headTokenIndex'] == hti && ( 
              token['dependencyEdge']['label'] == 'ACOMP' || token['dependencyEdge']['label'] == 'CONJ'
            )
          }
        end
        ro.flatten
      end

      def find_entities( name, entities )
        Log.debug(format('find_entities: %s', name))
        entities.select{|e| e['name'] == name }
      end

      def run( tokens, entities, descriptions )
        return if tokens == nil
        @subjects.each do |subject|
          bias_words = descriptions[subject.data[:is_described_with]]
          #Log.debug(format('Words: %s', words))

          ## find entity nouns
          subject.data[:is_described_as].each do |name|
            search_pool = []

            search_pool << find_conjectives( tokens, name )
            search_pool << find_attributes( tokens, name )

            search_pool.flatten!

            found_matches = search_pool.select{|f| bias_words.include? f['text']['content'] }
            @found_matches += found_matches.size
            if found_matches.size > 0
              Log.debug(format('Found words: %i', found_matches.size))
              pp found_matches
            end
          end
        end
      end

      def is( of, what )
        #Log.debug('is')
        @data[:of] = of
        @data[:what] = what
      end

      def subject( type, &block )
        if type == :person
          s = BiasEngineParts::Person.new()
          s.instance_eval( &block )
        else
          Log.fatal(format('Unknown subject type: %s', type))
          return nil
        end
        #pp s
        @subjects.push( s )
      end
    end

    class Subject
      @data 
      attr_accessor :data
      def initialize()
        @data = {}
      end
    end

    class Person < Subject

      def is_mentioned()
        @data[:is_mentioned] = true
      end

      def is_described_with( words )
        #Log.debug(format('is_described_with: %s', words))
        @data[:is_described_with] = words
      end

      def is_described_as( v )
        #Log.debug('is_described_as')
        @data[:is_described_as] = v
      end
    end
  end

end
