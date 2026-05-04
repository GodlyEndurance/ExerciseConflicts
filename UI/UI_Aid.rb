module UIAid
  WIDTH  = 60
  INDENT = "  "

  def indent(n = 1)
    INDENT * n
  end

  def divider(char = '─')
    puts "#{indent}#{char * (WIDTH - 4)}"
  end

  def header(text)
    puts "\n#{'═' * WIDTH}\n#{indent}#{text}\n#{'═' * WIDTH}"
  end

  def box(text)
    label   = "#{indent}#{text}"
    padding = WIDTH - label.length - 2
    puts "\n┌#{'─' * (WIDTH - 2)}┐"
    puts "│#{label}#{' ' * [padding, 0].max}│"
    puts "└#{'─' * (WIDTH - 2)}┘"
  end

  def prompt(msg)
    print "\n#{indent}#{msg} > "
    gets&.chomp&.strip
  end

  def ask(options)
    options.each { |k, v| puts "#{indent(2)}#{k}. #{v}" }
    puts "#{indent(2)}0. Quit"
    loop do
      input = prompt("Choice")
      return 0   if input == '0'
      return nil if input.nil?
      int = Integer(input) rescue nil
      return int if int && options.key?(int)
      puts "#{indent}Invalid choice, try again."
    end
  end
end
