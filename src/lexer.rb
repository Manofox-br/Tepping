class Lexer
  attr_reader :lines # Guarda as linhas originais para mostrar no erro

  def initialize(code)
    @original_code = code.dup
    @lines = code.lines
    @code = code.dup
    
    # Substitui comentários por espaços em branco para não quebrar a contagem de linhas e colunas
    @code.gsub!(/#=.*?=#/m) { |m| m.gsub(/[^\n]/, ' ') }
    @code.gsub!(/#.*/) { |m| ' ' * m.length }

    @line = 1
    @col = 1
  end

  def advance_pos(str)
    str.each_char do |c|
      if c == "\n"
        @line += 1
        @col = 1
      else
        @col += 1
      end
    end
  end

  def tokenize
    tokens = []
    until @code.empty?
      # Consome espaços em branco e atualiza a linha/coluna
      if match = @code.match(/\A\s+/)
        advance_pos(match[0])
        @code.sub!(/\A\s+/, '')
        next
      end

      break if @code.empty?

      tok_line = @line
      tok_col = @col

      # Helper para criar os tokens anotando a posição
      matched = false
      rules = {
        /\Aconsole\.print/ => :CONSOLE_PRINT,
        /\Avar\b/ => :VAR,
        /\Adef\b/ => :DEF,
        /\Afunc\b/ => :FUNC,
        /\Areturn\b/ => :RETURN,
        /\Awhile\b/ => :WHILE,
        /\Afor\b/ => :FOR,
        /\Ain\b/ => :IN,
        /\Arange\b/ => :RANGE,
        /\Acalc\b/ => :CALC,
        /\A\+=/ => :ASSIGN_ADD,
        /\A-=/ => :ASSIGN_SUB,
        /\A=/ => :ASSIGN,
        /\A\+/ => :PLUS,
        /\A-/ => :MINUS,
        /\A</ => :LESS,
        /\A\(/ => :LPAREN,
        /\A\)/ => :RPAREN,
        /\A\{/ => :LBRACE,
        /\A\}/ => :RBRACE,
        /\A:/ => :COLON,
        /\A,/ => :COMMA
      }

      rules.each do |regex, type|
        if match = @code.match(regex)
          tokens << { type: type, line: tok_line, col: tok_col }
          advance_pos(match[0])
          @code.sub!(regex, '')
          matched = true
          break
        end
      end

      next if matched

      # Regras com valores (Strings, Numeros, Variaveis)
      if match = @code.match(/\A\$var\(([^)]+)\)/)
        tokens << { type: :VAR_REF, value: $1, line: tok_line, col: tok_col }
        advance_pos(match[0])
        @code.sub!(/\A\$var\(([^)]+)\)/, '')
      elsif match = @code.match(/\A\$var\s+"([^"]+)"/)
        tokens << { type: :VAR_REF, value: $1, line: tok_line, col: tok_col }
        advance_pos(match[0])
        @code.sub!(/\A\$var\s+"([^"]+)"/, '')
      elsif match = @code.match(/\A"([^"\\]|\\.)*"/)
        val = match[0]
        tokens << { type: :STRING, value: val[1...-1], line: tok_line, col: tok_col }
        advance_pos(val)
        @code.sub!(/\A"([^"\\]|\\.)*"/, '')
      elsif match = @code.match(/\A\d+(\.\d+)?/)
        val = match[0]
        tokens << { type: :NUMBER, value: val.include?('.') ? val.to_f : val.to_i, line: tok_line, col: tok_col }
        advance_pos(val)
        @code.sub!(/\A\d+(\.\d+)?/, '')
      elsif match = @code.match(/\A[a-zA-Z_][a-zA-Z0-9_]*/)
        val = match[0]
        tokens << { type: :IDENTIFIER, value: val, line: tok_line, col: tok_col }
        advance_pos(val)
        @code.sub!(/\A[a-zA-Z_][a-zA-Z0-9_]*/, '')
      else
        raise "erro (Erro de Sintaxe) em #{tok_line}:#{tok_col}.\nCaractere inesperado próximo a '#{@code[0..5]}'"
      end
    end
    tokens
  end
end
