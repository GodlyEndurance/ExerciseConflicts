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
      sent        = saved_entries(@type)
      ex_opts     = @workout.exercises.each_with_index.to_h do |e, i|
        label = sent.include?("#{e} (Exercise)") ? "#{e}  (SENT)" : e
        [i + 1, label]
      end
      next_key    = (ex_opts.keys.max || 0) + 1
      nav_opts    = ex_opts.merge(
        next_key     => "-- Switch to Isolation Screen (#{@type})",
        next_key + 1 => "-- Back to screen select (#{@type})",
        next_key + 2 => "-- Different workout type",
        next_key + 3 => "-- Check workout type completion"
      )
      ex_choice = ask(nav_opts)
      return :quit if ex_choice == 0
      return :switch_to_isolation   if ex_choice == next_key
      return :back_to_screen_select  if ex_choice == next_key + 1
      return :back_to_types          if ex_choice == next_key + 2
      return :check_completion       if ex_choice == next_key + 3

      raw_name = ex_opts[ex_choice].sub(/  \(SENT\)$/, '')
      show_results(raw_name)
      save_entry(@type, 'Exercise', raw_name) if yes_no("Save \"#{raw_name}\" to PossibleWorkout.txt?")

      case next_action
      when :quit                  then return :quit
      when :change_type           then return :back_to_types
      when :switch_to_isolation   then return :switch_to_isolation
      when :back_to_screen_select then return :back_to_screen_select
      when :check_completion      then return :check_completion
      # :same_type => continue exercise loop
      end
    end
  end

  private

  def show_results(exercise)
    roles = @workout.muscle_targets[exercise]

    header("MUSCLES FOR: #{exercise}")
    ROLE_LABELS.each do |role, label|
      muscles = roles[role]
      next if muscles.nil? || muscles.empty?
      puts "\n#{indent}#{label}:"
      muscles.each { |m| puts "#{indent(3)}-->  #{m}" }
    end
    divider

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
                   4 => "Different workout type",
                   5 => "Check workout type completion" })
    case choice
    when 0 then :quit
    when 2 then :switch_to_isolation
    when 3 then :back_to_screen_select
    when 4 then :change_type
    when 5 then :check_completion
    else        :same_type
    end
  end
end
