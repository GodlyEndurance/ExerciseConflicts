require_relative 'UI_Aid'

# Handles the exercise selection and conflict display for one workout type.
class ExerciseScreen
  include UIAid

  def initialize(type, workout)
    @type    = type
    @workout = workout
    @cf      = ConflictFinder.instance
  end

  # Runs the exercise loop. Returns :back_to_types or :quit.
  def run
    loop do
      box("#{@type.upcase} -- SELECT EXERCISE")
      ex_opts   = @workout.exercises.each_with_index.to_h { |e, i| [i + 1, e] }
      ex_choice = ask(ex_opts)
      return :quit if ex_choice == 0

      show_results(ex_opts[ex_choice])
      save_entry(@type, 'Exercise', ex_opts[ex_choice]) if yes_no("Save \"#{ex_opts[ex_choice]}\" to PossibleWorkout.txt?")

      case next_action
      when :quit                 then return :quit
      when :change_type          then return :back_to_types
      when :switch_to_isolation  then return :switch_to_isolation
      when :back_to_screen_select then return :back_to_screen_select
      # :same_type => continue exercise loop
      end
    end
  end

  private

  def show_results(exercise)
    conflicts     = @cf.conflicts_for(exercise, @workout)
    non_conflicts = @workout.exercises.reject { |e| e == exercise || conflicts.key?(e) }

    header("CONFLICTS FOR: #{exercise}")
    if conflicts.empty?
      puts "\n#{indent}No conflicts found within #{@type} for \"#{exercise}\". (๑>◡<๑)"
    else
      conflicts.each do |other_ex, roles_map|
        puts "\n#{indent}◈ #{other_ex}"
        divider('·')
        roles_map.each do |role, muscles|
          puts "#{indent(2)}#{ROLE_LABELS[role]}:"
          muscles.each { |m| puts "#{indent(4)}-->  #{m}" }
        end
      end
    end

    header("NON-CONFLICTS FOR: #{exercise}")
    if non_conflicts.empty?
      puts "\n#{indent}All other exercises in #{@type} share muscle targets. (๑>◡<๑)"
    else
      non_conflicts.each { |e| puts "\n#{indent}◈ #{e}" }
    end

    divider
  end

  def next_action
    puts "\n#{indent}What would you like to do next?"
    choice = ask({ 1 => "Same workout type (#{@type})",
                   2 => "Switch to Isolation Screen (#{@type})",
                   3 => "Back to screen select (#{@type})",
                   4 => "Different workout type" })
    case choice
    when 0 then :quit
    when 2 then :switch_to_isolation
    when 3 then :back_to_screen_select
    when 4 then :change_type
    else        :same_type
    end
  end
end
