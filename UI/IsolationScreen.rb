require_relative 'UI_Aid'

# Handles muscle selection (filtered by workout type) and displays
# which exercises in that workout target the selected muscle.
class IsolationScreen
  include UIAid

  MUSCLES_BY_TYPE = {
    'Push'  => [
      'Anterior Deltoid', 'Medial Deltoid', 'Pectoralis Major',
      'Serratus Anterior', 'Triceps Brachii'
    ],
    'Pull'  => [
      'Biceps Brachii', 'Brachialis', 'Brachioradialis',
      'Forearm Flexors (Grip)', 'Lats (Latissimus Dorsi)',
      'Lower Traps', 'Middle Traps', 'Posterior Deltoid',
      'Rhomboids', 'Rotator Cuff', 'Teres Major', 'Upper Traps'
    ],
    'Lower' => [
      'Adductors', 'Gastrocnemius', 'Gluteus Maximus',
      'Gluteus Medius & Minimus', 'Hamstrings', 'Quadriceps'
    ],
    'Core'  => [
      'Erector Spinae', 'Hip Flexors', 'Obliques', 'Rectus Abdominis'
    ]
  }.freeze

  SEARCH_ROLES = %i[agonist].freeze

  def initialize(type, workout)
    @type    = type
    @workout = workout
    @muscles = MUSCLES_BY_TYPE[@type] || []
  end

  # Runs the isolation muscle loop. Returns :back_to_types or :quit.
  def run
    loop do
      box("#{@type.upcase} -- SELECT MUSCLE")
      muscle_opts = @muscles.each_with_index.to_h do |m, i|
        label = has_exercises?(m) ? m : "#{m}  (EMPTY)"
        [i + 1, label]
      end
      choice = ask(muscle_opts)
      return :quit if choice == 0

      muscle_name = muscle_opts[choice].sub(/\s+\(EMPTY\)$/, '')
      show_exercises(muscle_name)
      save_entry(@type, 'Muscle', muscle_name) if yes_no("Save \"#{muscle_name}\" to PossibleWorkout.txt?")

      case next_action
      when :quit                 then return :quit
      when :change_type          then return :back_to_types
      when :switch_to_exercise   then return :switch_to_exercise
      when :back_to_screen_select then return :back_to_screen_select
      # :same_type => continue muscle loop
      end
    end
  end

  private

  def has_exercises?(muscle_name)
    @workout.muscle_targets.any? do |_exercise, roles|
      roles[:agonist]&.any? { |m| m.casecmp(muscle_name).zero? }
    end
  end

  def show_exercises(muscle_name)
    header("EXERCISES FOR: #{muscle_name}")

    found = {}
    @workout.muscle_targets.each do |exercise, roles|
      SEARCH_ROLES.each do |role|
        if roles[role]&.any? { |m| m.casecmp(muscle_name).zero? }
          (found[exercise] ||= []) << role
        end
      end
    end

    if found.empty?
      puts "\n#{indent}No exercises found targeting \"#{muscle_name}\" in #{@type}."
    else
      found.each do |exercise, roles|
        puts "\n#{indent}◈ #{exercise}"
        divider('·')
        roles.each { |r| puts "#{indent(2)}#{ROLE_LABELS[r]}" }
      end
    end

    divider
  end

  def next_action
    puts "\n#{indent}What would you like to do next?"
    choice = ask({ 1 => "Same workout type (#{@type})",
                   2 => "Switch to Exercise Screen (#{@type})",
                   3 => "Back to screen select (#{@type})",
                   4 => "Different workout type" })
    case choice
    when 0 then :quit
    when 2 then :switch_to_exercise
    when 3 then :back_to_screen_select
    when 4 then :change_type
    else        :same_type
    end
  end
end
