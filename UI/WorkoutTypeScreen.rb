require_relative 'UI_Aid'
require_relative 'ExerciseScreen'
require_relative 'IsolationScreen'
require_relative 'WorkoutTypeCompletion'

# Handles workout type selection, then routes to ExerciseScreen or IsolationScreen.
class WorkoutTypeScreen
  include UIAid

  SCREEN_OPTS = { 1 => 'Exercise Screen', 2 => 'Isolation Screen' }.freeze

  def initialize(workouts)
    @workouts  = workouts
    @type_opts = WORKOUT_KEYS.each_with_index.to_h { |t, i| [i + 1, t] }
  end

  # Runs the workout type loop. Returns when the user quits.
  def run
    loop do
      box("SELECT WORKOUT TYPE")
      type_choice = ask(@type_opts)

      if type_choice == 0
        puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
        exit
      end
      next unless type_choice

      type          = @type_opts[type_choice]
      screen_choice = select_screen(type)

      if screen_choice == 0
        puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
        exit
      end
      next unless screen_choice

      screen = screen_choice == 1 ? ExerciseScreen.new(type, @workouts[type][:ce])
                                   : IsolationScreen.new(type, @workouts[type][:ie])
      loop do
        result = screen.run
        case result
        when :quit
          puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
          exit
        when :switch_to_isolation
          screen = IsolationScreen.new(type, @workouts[type][:ie])
        when :switch_to_exercise
          screen = ExerciseScreen.new(type, @workouts[type][:ce])
        when :check_completion
          WorkoutTypeCompletion.new(@workouts).run
        when :back_to_screen_select
          new_choice = select_screen(type)
          if new_choice == 0
            puts "\n#{indent}Goodbye! (๑>◡<๑)\n"
            exit
          end
          screen = new_choice == 1 ? ExerciseScreen.new(type, @workouts[type][:ce])
                                   : IsolationScreen.new(type, @workouts[type][:ie])
        else
          break # :back_to_types => fall through to workout type loop
        end
      end
    end
  end

  private

  def select_screen(type)
    box("#{type.upcase} -- SELECT SCREEN")
    ask(SCREEN_OPTS)
  end
end
