require_relative 'UI_Aid'
require_relative 'ExerciseScreen'

# Handles workout type selection and delegates to ExerciseScreen.
class WorkoutTypeScreen
  include UIAid

  def initialize(workouts)
    @workouts  = workouts
    @type_opts = WORKOUT_KEYS.each_with_index.to_h { |t, i| [i + 1, t] }
  end

  # Runs the workout type loop. Returns when the user quits.
  def run
    loop do
      box("SELECT WORKOUT TYPE")
      choice = ask(@type_opts)

      if choice == 0
        puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
        exit
      end

      result = ExerciseScreen.new(@type_opts[choice], @workouts[@type_opts[choice]]).run

      if result == :quit
        puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
        exit
      end
      # :back_to_types => continue workout type loop
    end
  end
end
