class Interpreter
  class ReturnException < StandardError
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  def initialize(ast, source_lines)
    @ast = ast
    @source_lines = source_lines
    @variables = {}
    @functions = {}
    @call_stack = []
  end

  def run
    execute(@ast)
  end

  private

  def sanitize_var(name)
    name.to_s.strip.gsub(/^["']|["']$/, '')
  end

  def throw_tepping_error(type, msg, line, col, highlight_target)
    line_text = @source_lines[line - 1].chomp rescue ""
    
    if line_text.include?(highlight_target)
      line_text = line_text.sub(highlight_target, "=>#{highlight_target}<=")
    else
      line_text = "=>#{line_text}<="
    end

    puts "erro (#{type}) em linha:#{line}:#{col}."
    puts "\"#{line_text}\""
    puts msg
    exit(1)
  end

  def execute(node)
    return nil if node.nil?

    case node[:type]
    when :program
      node[:body].each { |stmt| execute(stmt) }
      nil
    when :var_decl
      @variables[sanitize_var(node[:name])] = evaluate(node[:value])
      nil
    when :var_add
      name = sanitize_var(node[:name])
      val = evaluate(node[:value])
      current_val = @variables[name] || 0
      @variables[name] = current_val + val
      nil
    when :var_sub
      name = sanitize_var(node[:name])
      val = evaluate(node[:value])
      current_val = @variables[name] || 0
      @variables[name] = current_val - val
      nil
    when :def_decl
      @functions[node[:name]] = { params: node[:params], body: node[:body] }
      nil
    when :return_stmt
      val = node[:value] ? evaluate(node[:value]) : nil
      raise ReturnException.new(val)
    when :while_stmt
      while evaluate(node[:condition])
        begin
          node[:body].each { |stmt| execute(stmt) }
        rescue ReturnException => e
          raise e
        end
      end
      nil
    when :for_stmt
      limit = evaluate(node[:range_expr]).to_i
      var_name_clean = sanitize_var(node[:var_name]) # Passa pelo filtro

      (0...limit).each do |i|
        @variables[var_name_clean] = i
        begin
          node[:body].each { |stmt| execute(stmt) }
        rescue ReturnException => e
          raise e
        end
      end
      nil
    when :print_stmt
      puts evaluate(node[:argument]).to_s
      nil
    when :expr_stmt
      evaluate(node[:expression])
      nil
    end
  end

  def evaluate(node)
    case node[:type]
    when :literal
      if node[:value].is_a?(String)
        interpolate_string(node[:value], node[:line], node[:col])
      else
        node[:value]
      end
    when :var_ref
      var_name_clean = sanitize_var(node[:name])
      unless @variables.key?(var_name_clean)
        throw_tepping_error("Variáveis não defnidas", "$var(#{var_name_clean}) não foi defnida", node[:line], node[:col], "$var(#{node[:name]})")
      end
      @variables[var_name_clean]
    when :binary_op
      left = evaluate(node[:left])
      right = evaluate(node[:right])
      case node[:op]
      when :+
        if left.is_a?(String) || right.is_a?(String)
          left.to_s + right.to_s
        else
          left + right
        end
      when :-
        left - right
      when :<
        left < right
      end
    when :func_call
      func = @functions[node[:name]]
      
      if @call_stack.include?(node[:name])
        throw_tepping_error("Loops de funções", "você não pode iniciar uma função dentro de uma função", node[:line], node[:col], "func \"#{node[:name]}\"()")
      end

      raise "erro em #{node[:line]}:#{node[:col]}.\nFunção '#{node[:name]}' não definida." if func.nil?

      @call_stack.push(node[:name])

      old_vars = @variables.dup
      func[:params].each_with_index do |param, idx|
        @variables[sanitize_var(param)] = evaluate(node[:arguments][idx])
      end

      ret_val = nil
      begin
        func[:body].each { |stmt| execute(stmt) }
      rescue ReturnException => e
        ret_val = e.value
      ensure
        new_vars = @variables
        @variables = old_vars
        # Remove variáveis locais da função, mantendo as globais
        new_vars.each do |k, v|
          @variables[k] = v unless func[:params].map { |p| sanitize_var(p) }.include?(k)
        end
        @call_stack.pop
      end
      ret_val
    when :calc_expr
      evaluate(node[:expression])
    end
  end

  def interpolate_string(str, line, col)
    result = str.dup
    
    result.gsub!(/\$\$var\(([^)]+)\)/, '§§VAR(\1)§§')
    
    result.gsub!(/\$var\(([^)]+)\)/) do |match|
      var_name = sanitize_var($1) # Passa pelo filtro na hora de buscar!
      
      unless @variables.key?(var_name)
        # Passa o 'match' completo (ex: $var(i)) para a setinha =>...<= focar exatamente nele
        throw_tepping_error("Variáveis não defnidas", "$var(#{var_name}) não foi defnida", line, col, match)
      end
      @variables[var_name].to_s
    end
    
    result.gsub!(/§§VAR\(([^)]+)\)§§/, '$var(\1)')
    
    result
  end
end

