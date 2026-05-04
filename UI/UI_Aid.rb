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

  def yes_no(msg)
    loop do
      input = prompt("#{msg} (y/n)")
      return true  if input&.downcase == 'y'
      return false if input&.downcase == 'n'
      puts "#{indent}Enter y or n."
    end
  end

  OUTPUT_PATH = File.join(File.dirname(__FILE__), '..', 'PossibleWorkout.txt')

  # Appends +entry+ (tagged with +label+) under the +type+ section of
  # PossibleWorkout.txt, keeping all sections grouped by workout type.
  def save_entry(type, label, entry)
    sections = Hash.new { |h, k| h[k] = [] }

    if File.exist?(OUTPUT_PATH)
      current_section = nil
      File.foreach(OUTPUT_PATH) do |line|
        line = line.chomp
        if line =~ /^=== (.+) ===/
          current_section = $1
        elsif current_section && !line.strip.empty?
          sections[current_section] << line
        end
      end
    end

    tagged = "#{entry} (#{label})"
    if sections[type].include?(tagged)
      puts "\n#{indent}Already saved."
      return
    end

    sections[type] << tagged

    File.open(OUTPUT_PATH, 'w') do |f|
      WORKOUT_KEYS.each do |t|
        next if sections[t].empty?
        f.puts "=== #{t} ==="
        sections[t].each { |e| f.puts e }
        f.puts
      end
    end

    puts "\n#{indent}Saved to PossibleWorkout.txt! (๑>◡<๑)"
  end
end
