
require 'json'
require 'citrus'

module CombinatorLogic

  dir = File.dirname File.expand_path __FILE__
  Citrus.load File.join dir, 'CL.citrus'
  
  class CLVar < String
    alias reduce dup
    def lgh; 1; end
    def name; self; end
  end

  class CLTerm
    attr_reader :terms
    
    def initialize *args
      @terms = args
    end

    def call *terms
      self.class.new *@terms, *terms
    end
    
    def to_s
      @terms.inject(name) do |s,t|
        if t.lgh > 1
          s << "(" << t.to_s << ")"
        else
          s << t.to_s
        end
      end
    end

    def reduce
      if @terms.size.zero?
        return self
      elsif @terms.size == 1
        return @terms.first.reduce
      end

      terms = @terms.map(&:reduce)
      if terms.first.respond_to? :call
        terms.drop(1).inject(terms.first, &:call).reduce
      else
        CLTerm.new *terms
      end
    end
    
    def lgh
      @terms.map(&:lgh).reduce(&:+).to_i
    end

    def name
      ""
    end

    def == other
      other.is_a?(CLTerm) and
        to_s == other.to_s
    end
    
  end

  class S < CLTerm
    def reduce
      if @terms.size < 3
        S.new *@terms.map(&:reduce)
      elsif @terms.size == 3
        x,y,z = *@terms.map(&:reduce)
        a = CLTerm.new(x, z)
        b = CLTerm.new(y, z)
        CLTerm.new(a, b)
      else
        @terms.drop(3).
          inject S.new(*@terms.take(3)).reduce,
                 &:call
      end
    end

    def lgh
      1 + super
    end

    def name
      'S'
    end
  end

  class K < CLTerm
    def reduce
      if @terms.size < 2
        K.new *@terms.map(&:reduce)
      elsif @terms.size == 2
        @terms.first.reduce
      else
        CLTerm.new @terms.first.reduce, *@terms.drop(2)
      end
    end
    
    def lgh
      1 + super
    end

    def name
      'K'
    end

  end

  class I < CLTerm
    def lgh
      1 + super
    end

    def name
      'I'
    end
  end

  class DerivedTerm < CLTerm

    attr_reader :name, :lgh
    alias to_s name
    
    def initialize name, *args
      @terms = args
      @name = name
      @lgh = 1
    end

    def call *args
      CLTerm.new self, *args
    end
    
  end

  class CLFile
    def initialize filename, data = nil
      begin
        @data = data || File.open(filename, 'r') { |f| f.read }
        @matches = CL.parse @data
      rescue => error
        @error = error
      end
    end

    def spans
      raise @error if @error
      if @spans.nil?
        @spans = []
        create_spans @matches
      end
      @spans
    end

    def value
      raise @error if @error
      @matches.value
    end

    def to_json
      if @error
        '{"error":' << @error.message.to_json << '}'
      else
        '{"spans":' << spans.to_json << '}'
      end
    end

    def self.from_source source
      CLFile.new nil, source
    end
    
    private
    def create_spans m
      [:any, :valued, :expression].each do |rule|
        if t = m.capture(rule)
          rule = t.events.first.to_s
          if ['print', 'reduce', 'reducestar',
              'expression', 'assignment'].include? rule
            @spans << [rule, t.offset + 1, t.offset + 1 + t.length]
          end
        end
      end
      m.matches.each { |m| create_spans m }
    end
  end
  
  module Helpers
    def s *args
      S.new *args
    end

    def k *args
      K.new *args
    end

    def i *args
      I.new *args
    end

    def b *args
      DerivedTerm.new( 'B', s(k(s),k) ).call *args
    end

    def bprime *args
      DerivedTerm.new( "B'", s(k(s(b)),k) ).call *args
    end

    def w *args
      DerivedTerm.new( 'W', s(s,k(i)) ).call *args
    end

    def var arg
      CLVar.new arg.to_s
    end

    extend self
    CLTerms = {
      'S' => S.new, 'K' => K.new, 'I' => I.new,
      'B'  => DerivedTerm.new( 'B', s(k(s),k) ),
      "B'" => DerivedTerm.new( "B'", s(k(s(b)),k) ),
      'W'  => DerivedTerm.new( 'W', s(s,k(i)) ) }
  end
  
end
